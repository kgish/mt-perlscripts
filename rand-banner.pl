#!/usr/bin/perl

use strict;
use warnings;

# rand-banner.pl [crontab] :
# If called with 'crontab' just create the file list of banners,
# otherwise return the binary contents of a random banner immage
# for displaying on a web page.

use CGI;
my $cgi = new CGI;

# Directories based from root dir.
my $root_dir = "/www/kiffingish.com";
my $cgi_dir = "$root_dir/cgi-bin";
my $doc_dir = "$root_dir/docs";
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

# Get the binary contents of the image file.
open (IMAGE, $img) or die "Cannot open image file '$img' for reading ($!)";
my $size = -s $img;
my $data;
read IMAGE, $data, $size;
close (IMAGE);

# Return image data to the caller.
print $cgi->header(-type=>"image/$ext2typ{$ext}"), $data;
