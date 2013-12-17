#!/usr/bin/perl -w
use strict;

use File::stat;
use JSON;

use Config::IniFiles;
my $cfg = Config::IniFiles->new( -file => "config.ini" );

my $root_path = $cfg->val( 'visitors', 'root_path' );
my $doc_dir = $cfg->val( 'visitors', 'doc_dir' );

my $doc_path ="$root_path/$doc_dir";

my $months = 6;

my $visitors_json = "$doc_path/visitors.json";

my $dirname = $cfg->val( 'visitors', 'dirname' );
my $parsing = 0;
my %list;

opendir(DIR, $dirname) or die "cannot open directory: '$dirname'";
my @docs = sort {
    my $a_stat = stat("$dirname/$a"); my $b_stat = stat("$dirname/$b");
    $b_stat->mtime <=> $a_stat->mtime; } grep(/www\.kiffingish\.com\.txt$/, readdir(DIR));
foreach my $file (@docs) {
    last  unless $months--;
    $file =~ /^awstats(\d\d)(\d\d\d\d)\./;
    my ($month, $year) = ($1, $2);
    my $filepath = "$dirname/$file";
    open (FH, $filepath) or die "could not open file: '$filepath'\n";
    my $found = 0;
    while(<FH>){
        if ($parsing) {
            if (/^END_GENERAL/) {
                $parsing--;
                $found++;
            }
        } else {
            if (/^BEGIN_GENERAL/) {
                $parsing++;
                next;
            }
        }
        if ($parsing) {
            if (/^Total(Unique|Visits)/) {
                chomp($_);
                my ($keyword, $num) = split(/ /, $_);
                $list{"$year-$month"}->{$keyword} = $num;
                $list{$keyword} += $num;
            }
        }
        last if $found;
    }
}

open my $fh, ">", $visitors_json or die "Cannot open file '$visitors_json' ($!)";
print $fh to_json(\%list, { utf8 => 1, pretty => 1 } );
close $fh;

# --------------------------------------------------------------------------
# <script type="text/javascript">
#   $(document).ready(function() { 
#     $.getJSON("http://www.kiffingish.com/visitors.json", function(data){
#       var totalvisits, totalunique; 
#       var rows = new Array();
#       $.each(data, function(key, name){
#         if (key === 'TotalVisits') {
#           totalvisits = name;
#         } else if (key === 'TotalUnique') {
#           totalunique = name;
#         } else {
#           var s = key.split("-");
#           rows.push(s[0] + " " + s[1] + " " + name.TotalUnique + " " +  \
#             name.TotalVisits);
#         }
#       });
#       rows.sort();
#       var months = [ "January", "February", "March", "April", "May",    \
#         "June", "July", "August", "September", "October", "November",   \
#           "December" ];
#       $.each(rows, function( i, value ) {
#         var n = value.split(" ");
#         $('#visitors').append("<tr><td>" + months[Number(n[1]) - 1] +   \
#           " " + n[0] + "</td><td align='right'>" + n[2] + \
#           "</td><td align='right'>" + n[3] + "</td></tr>");
#       });
#       $('#visitors').append("<tr><td>Totals</td><td align='right'>" +   \
#         totalvisits + "</td><td align='right'>" + totalunique +         \
#         "</td></tr>");
#     });
#   });
# </script>
#
# ...
#
# <p>
# Here are the total and unique visitors during the last six months.
# </p>
#
# <style>
# #visitors {
#     width:75%;
#     border:1px solid black;
# }
# #visitors th.alignright {
#     text-align: right;
# }
# #visitors th {
#     background: #eee;
#     width: 25%;
#     font-weight: bold;
#     padding: 2px;
#     border-bottom: 1px solid black;
# }
# #visitors td {
#     width: 25%;
#     padding: 2px;
# }
# #visitors tr:last-child td {
#     background: #eee;
#     font-weight: bold;
#     border-top: 1px solid black;
# }
# </style>
#
# <table id="visitors">
#     <tr><th>Month</th><th class="alignright">Unique</th><th             \
#       class="alignright">Total</th></tr>
# </table>
# --------------------------------------------------------------------------
