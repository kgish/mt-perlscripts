#!/usr/bin/perl -w
use strict;

#use URI::Escape;
use File::stat;
use JSON;
require LWP::UserAgent;

use Config::IniFiles;
my $cfg = Config::IniFiles->new( -file => "config.ini" );

my $root_path = $cfg->val( 'blogentries', 'root_path' );
my $doc_dir = $cfg->val( 'blogentries', 'doc_dir' );

my $doc_path ="$root_path/$doc_dir";

my $max = $cfg->val( 'blogentries', 'max' );
my $months = $cfg->val( 'blogentries', 'months' );

my $blogentries_json = "$doc_path/blogentries.json";

my $ua = LWP::UserAgent->new;
my $timeout = $cfg->val( 'blogentries', 'timeout' );

my $dirname = $cfg->val( 'blogentries', 'dirname' );
my $parsing = 0;
my %list;

opendir(DIR, $dirname) or die "cannot open directory: '$dirname'";
my @docs = sort {
    my $a_stat = stat("$dirname/$a"); my $b_stat = stat("$dirname/$b");
    $b_stat->mtime <=> $a_stat->mtime; } grep(/www\.kiffingish\.com\.txt$/, readdir(DIR));
foreach my $file (@docs) {
    #print "$file\n";
    last  unless $months--;
    my $filepath = "$dirname/$file";
    open (FH, $filepath) or die "could not open file: '$filepath'\n";
    my $found = 0;
    while(<FH>){
        if ($parsing) {
            if (/^END_SIDER$/) {
                $parsing--;
                $found++;
            }
        } else {
            if (/^BEGIN_SIDER \d+$/) {
                $parsing++;
                next;
            }
        }
        if ($parsing) {
            my ($file, $num, $dummy) = split(/ /, $_);
            $list{$file} += $num;
        }
        last if $found;
    }
}

my @entries;

foreach my $key (sort { $list{$b} <=> $list{$a} } keys %list) {
    next unless ($key =~ (/^\//));
    next if ($key =~ (/^(\/|\/blog\/)$/));
    next if ($key =~ (/\.(pl|cgi|txt|php|gif|png|jpg|jpeg|json)$/i));
    next if ($key =~ (/mt\-comments\.cgi/));
    next if ($key =~ (/^\/mt\-static/));
    next if ($key =~ (/^\/images\//));
    my $title = "ERROR";
    my $url = "http://www.kiffingish.com$key";
    my $response = $ua->get($url);
    if ($response->is_success) {
        $title = $response->title() || "NO_TITLE";
    }
    else {
        $title = "ERROR - " . $response->status_line;
    }
    last if $title eq "NO_TITLE";
    last unless $max--;
    $title =~ s/ \- Kiffin Gish dot Com$//;
    $title =~ s/^Kiffin Gish dot Com: //;
    push (@entries, "$list{$key}:$key:$title");
}

open my $fh, ">", $blogentries_json or die "Cannot open file '$blogentries_json' ($!)";
print $fh to_json(\@entries, { utf8 => 1, pretty => 1 } );
close $fh;

# --------------------------------------------------------------------------
# $.getJSON("http://www.kiffingish.com/blogentries.json",
#     function(data){
#         $.each(data, function(i, field){
#             var n = field.split(":");
#             // n[0] = number, n[1] = url, n[2] = title
#     });
# });
# --------------------------------------------------------------------------
