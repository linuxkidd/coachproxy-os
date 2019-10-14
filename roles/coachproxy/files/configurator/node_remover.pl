#!/usr/bin/perl -w
#
# Copyright (C) 2019 Wandertech LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Removes all nodes whose names contain the provided tags. If a selected
# node also contains the /+pred/ tag, all preceeding nodes will also be
# removed.

use strict;

if ( scalar(@ARGV) < 2 ) {
  print "Usage: $0 filename substr [substr...]\n\n";
  print "Example: $0 flows_coachproxy.json /elecheat2018/ /light_1/\n\n";
  print "If a node's name contains the tag /+pred/ in the json source, all preceeding\n";
  print "nodes will also be removed.\n";
  exit;
}

my $filename = shift;

# Pass 1
#
# Get a list of the IDs of each object matching the provided list of names.
# The jq code to accomplish this will look something like this:
#
# .[] | select( (.name != null) and (.name | contains("/heatelec-g8/") or contains("/heatfuel-g8/"))) | .id
#
# ".[]" takes the input array and passes each element to the next code block.
# "select(logic)" only returns objects that match the provided logic.
# ".name != null" is required to prevent errors, since some objects (e.g. dashboard tabs) don't have .name
# ".name |" passes the .name field of an object to the next code block.
# "contains(string)" returns true if string is found inside the input to the code block.
# "| .id" returns the values of the .id parameters in the output of "select()".
# The entire code is wrapped in [] to turn the results into an array.
#
# Two lists are obtained: One for nodes that should be deleted individually (node name does not contain
# the /+pred/ tag), and one for ndoes that should also have all their preceeding nodes removed.

sub do_filter {
  my $filter = shift;

  my $first = 1;
  foreach my $name (@_) {
    if ($first == 0) { $filter .= " or"; }
    $filter .= " contains(\"$name\")";
    $first = 0;
  }

  $filter .= " )) | .id";

  my $ids = `jq '$filter' < $filename`;

  return $ids;
}

my ($filter_setup, $ids_to_delete, $ids_with_preds, $all_ids);

$filter_setup = '.[] | select( (.name != null) and (.name | contains("/+pred/") == false) and (.name | ';
$ids_to_delete = do_filter("$filter_setup", @ARGV);

$filter_setup = '.[] | select( (.name != null) and (.name | contains("/+pred/") == true) and (.name | ';
$ids_with_preds = do_filter("$filter_setup", @ARGV);

$all_ids = "$ids_to_delete$ids_with_preds";

# Pass 2
#
# Get a list of the IDs of each object containing a wire to an object on the
# previously matched "with_predecessors" list.
#
# .[] | select( (.wires != null) and (.wires | contains([["fe6cb3e6.b5088"]]))) | .id

my $remaining = 8;   # Don't loop back more than 8 levels, to prevent infinite loops
while ($ids_with_preds && $remaining > 0) {

  my $filter = ".[] | select( (.wires != null) and (.wires | ";

  my $first = 1;
  foreach my $id (split ' ', $ids_with_preds) {
    if ($first == 0) { $filter .= " or "; }
    $filter .= "contains([[$id]])";
    $first = 0;
  }

  $filter .= " )) | .id";

  my $ids = `jq '$filter' < $filename`;

  $all_ids .= "$ids";
  $ids_with_preds = $ids;   # Next loop, check the latest batch of nodes for predecessors

  $remaining--;
  if ($ids eq '') { last; }  # If nothing was found, abort
}

my $uniq_ids = `echo "$all_ids" | sort -u`;

# Pass 3
#
# Filter the source file removing all nodes previously identified.
#
# [ .[] | select( (.name == null) or (.name | contains("/heatelec-g8/") == false and contains("/heatfuel-g8/") == false and contains("/waterpump-g8/") == false )) ]

my @uniq_ids = split ' ', $uniq_ids;
if (scalar(@uniq_ids) > 0) {
  my $filter = "[ .[] | select( .id | ";

  my $first = 1;
  foreach my $id (@uniq_ids) {
    if ($first == 0) { $filter .= " and "; }
    $filter .= "contains(\"$id\") == false";
    $first = 0;
  }

  $filter .= " ) ]";

  system("jq '$filter' < $filename > /tmp/node_remover_temp");
  system("mv /tmp/node_remover_temp $filename");
}
