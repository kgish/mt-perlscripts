#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Carp 'fatalsToBrowser';
use List::Util qw(shuffle);
use JSON;

use Config::IniFiles;
my $cfg = Config::IniFiles->new( -file => "config.ini" );

my $line;

# ----------------------------------------------------------------------- 
# In MovableType I have created an index which serves as the input
# for randomly selecting one of the existing entries. in my case the
# file happens to be called 'entries.lst' and it's generated like this:
#
# <mt:Entries lastn="0">
# <$mt:EntryDate format="%B %e,
# %Y"$>|||<$mt:EntryTitle$>|||<$mt:EntryPermalink$>|||<$mt:EntryBody
# words="30" convert_breaks="0" sanitize="1" $>|||</mt:Entries>
#
# ----------------------------------------------------------------------- 
my $file = $cfg->val( 'rand-entry', 'file' );

srand;

my $q = new CGI;

my $mode = $q->param('mode');
my $max = $q->param('max');
$mode ||= 'html';
$max ||= $mode eq 'list' ? 5 : 1;

die "unknowm mode '$mode'" unless ($mode eq 'redirect' || $mode eq 'html' || ($mode eq 'list'));

if ($mode eq 'list')
{
    open FH, '<', $file or die "Cannot open file '$file': $!";
    my @lines = <FH>;
    close FH;
    my @shuffled_indexes = shuffle(0..$#lines);

    # Get just max of them.
    my @pick_indexes = @shuffled_indexes[ 0 .. $max - 1 ];  
    my @picked_lines = @lines[@pick_indexes];
    my @entries;
    for (my $i = 0; $i < $#picked_lines +1; $i++)
    {
        my ($date, $title, $url, $contents) = split('\|\|\|', $picked_lines[$i]);
        $entries[$i] = {date => $date, title => $title, url => $url};
        # print "$date\n$title\n$url\n\n";
    }
    print $q->header(-type=>'application/json');
    print to_json(\@entries, { utf8 => 1, pretty => 1 } )
}
else
{
    open FH, '<', $file or die "Cannot open file '$file': $!";
    rand($.) < 1 && ($line = $_) while <FH>;
    chomp($line);
    close FH;
    my ($date, $title, $url, $contents) = split('\|\|\|', $line);

    if ($mode eq 'redirect')
    {
        print $q->redirect($url);
        exit;
    }
    elsif ($mode eq 'html')
    {
        print $q->header();
        print $q->start_html;
        print qq{<dl><dt><a href="$url">$title</a> $date</dt><dd>$contents <a href="$url">...</a></dd><dt></dl>};
        print $q->end_html;
    }
}
