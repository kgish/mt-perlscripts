#!/usr/bin/perl

use strict;
use warnings;

# rand-banner.pl [crontab] :
# If called with 'crontab' just create the file list of banners,
# otherwise return the binary contents of a random banner immage
# for displaying on a web page.

use CGI;
my $cgi = new CGI;

use Config::IniFiles;
my $cfg = Config::IniFiles->new( -file => "config.ini" );

# Directories based from root dir.
my $root_path = $cfg->val( 'rand-banner', 'root_path' );
my $cgi_dir = "$root_path/cgi-bin";
my $doc_dir = "$root_path/docs";
my $img_dir = "$doc_dir/images/banners";
my $banners_lst = "banners.lst";

# Coversion file ext to http img/type.
my %ext2typ = (
    bmp => 'bmp',
    gif => 'gif',
    jpeg => 'jpeg',
    jpg  => 'jpeg',
    png  => 'png',
    tif  => 'tiff',
    tiff => 'tiff',
);

# Only interested in the following file types.
my $img_filter = join(',', keys %ext2typ);

# If called with 'crontab' or banners.lst does not exist, collect
# list of banners from 905x170 files in images directory.
my $crontab = (defined($ARGV[0]) && ($ARGV[0] eq 'crontab'));
if ($crontab || (! -f $banners_lst))
{
    # See: http://www.imagemagick.org/script/identify.php
    my $output = `identify $img_dir/*.{$img_filter} 2>/dev/null |grep ' 905x170 ' | sed 's/ .*//' | sed 's/\\[.*//' | sed 's/^.*\\///'`;
    open my $fh, ">", $banners_lst or die "Cannot open file '$banners_lst' for writing ($!)";
    print $fh $output;
    close $fh;
}

# All done if called from crontab.
exit if $crontab;

# Grab the latest banner list.
open my $fh, "<", $banners_lst or die "Cannot open file '$banners_lst' for reading ($!)";
my @banners = <$fh>;
close $fh;

# Take a random item from the list.
my $banner = $banners[rand @banners];
chomp($banner);

# Define banner image filepath.
$banner =~ /^.*\.(.*)$/;
my $ext = $1;
my $img = "$img_dir/$banner";

#print "$banner\n"; exit;

# Get the binary contents of the image file.
open (IMAGE, $img) or die "Cannot open image file '$img' for reading ($!)";
my $size = -s $img;
my $data;
read IMAGE, $data, $size;
close (IMAGE);

# Return image data to the caller. Be sure to disable caching so
# that each new request returns a new banner image.
print "Content-type: image/$ext2typ{$ext}\n";
print "Cache-Control: max-age=0, no-cache, no-store, must-revalidate\n";
print "Pragma: no-cache\n";
print "Expires: Wed, 11 Jan 1984 05:00:00 GMT\n";
print "\n";
print $data;
