#!/usr/bin/perl -w
use strict;

use URI::Escape;
use File::stat;
use JSON;

use Config::IniFiles;
my $cfg = Config::IniFiles->new( -file => "config.ini" );

my $line;
my $root_path = $cfg->val( 'blogentries', 'root_path' );
my $doc_dir = $cfg->val( 'blogentries', 'doc_dir' );

my $doc_path ="$root_path/$doc_dir";

my $max = $cfg->val( 'blogentries', 'max' );
my $months = $cfg->val( 'blogentries', 'months' );

my $searchphrases_json = "$doc_path/searchphrases.json";

my $dirname = $cfg->val( 'blogentries', 'dirname' );
my $parsing = 0;
my %list;

opendir(DIR, $dirname) or die "cannot open directory: '$dirname'";
my @docs = sort {
    my $a_stat = stat("$dirname/$a"); my $b_stat = stat("$dirname/$b");
    $b_stat->mtime <=> $a_stat->mtime; } grep(/www\.kiffingish\.com\.txt$/, readdir(DIR));
foreach my $file (@docs) {
    my $filepath = "$dirname/$file";
    open (FH, $filepath) or die "could not open file: '$filepath'\n";
    my $found = 0;
    while(<FH>){
        if ($parsing) {
            if (/^END_SEARCHWORDS/) {
                $parsing--;
        $found++;
            }
        } else {
            if (/^BEGIN_SEARCHWORDS/) {
                $parsing++;
                next;
            }
        }
        if ($parsing) {
            my ($phrase, $num) = split(/ /, $_);
            $phrase =~ s/\+/ /g;
            $phrase = uri_unescape($phrase);
            chomp($num);
            $list{$phrase} += $num;
        }
    last if $found;
    }
    last  unless $months--;
}

my @entries;

foreach my $key (sort { $list{$b} <=> $list{$a} } keys %list) {
    last  unless $max--;
    push (@entries, "$list{$key}:$key");
}

open my $fh, ">", $searchphrases_json or die "Cannot open file '$searchphrases_json' ($!)";
print $fh to_json(\@entries, { utf8 => 1, pretty => 1 } );
close $fh;

# --------------------------------------------------------------------------
# $.getJSON("http://www.kiffingish.com/searchphrases.json",
#     function(data){
#         $.each(data, function(i, field){
#             var n = field.split(":");
#             // n[0] = phrase, n[1] = number
#     });
# });
# --------------------------------------------------------------------------
