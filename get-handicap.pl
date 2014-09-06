#!/usr/bin/perl -w

use strict;
use warnings;

# get_handicap.pl [crontab]
# If called with 'crontab' then scrape the ngf handicap website
# for my handicap and create/modify the file with my handicap,
# otherwise return my handicap as defined in this file.

use LWP::UserAgent;
use HTML::TreeBuilder::XPath;

use CGI;
my $cgi = new CGI;

use Config::IniFiles;
my $cfg = Config::IniFiles->new( -file => "config.ini" );

# Directories based from root dir.
my $root_path = $cfg->val( 'get-handicap', 'root_path' );
my $url = $cfg->val( 'get-handicap', 'url' );
my $xpath = $cfg->val( 'get-handicap', 'xpath' );
my $cgi_dir = "$root_path/cgi-bin";
my $handicap_txt = "handicap.txt";

#
# If called with 'crontab' or handicap.txt does not exist, get
# the handicap and save to handicap.txt file.
my $crontab = (defined($ARGV[0]) && ($ARGV[0] eq 'crontab'));
if ($crontab || (! -f $handicap_txt))
{
    my $ua = LWP::UserAgent->new();
    my $tree = HTML::TreeBuilder::XPath->new;

    my $response = $ua->get($url);
    die $response->status_line unless $response->is_success;

    $tree->ignore_unknown(0);
    $tree->parse($response->decoded_content);
    $tree->eof;

    my @nodes = $tree->findnodes($xpath);
    my $handicap = $nodes[0]->as_text;

    #print "handicap is $handicap\n";
    open my $fh, ">", $handicap_txt or die "Cannot open file '$handicap_txt' for writing ($!)";
    print $fh $handicap;
    close $fh;
}

# All done if called from crontab.
exit if $crontab;

# Grab the latest handicap.
open my $fh, "<", $handicap_txt or die "Cannot open file '$handicap_txt' for reading ($!)";
my $handicap= <$fh>;
close $fh;

# Return image data to the caller.
print $cgi->header(-type=>"text/plain"), $handicap;
