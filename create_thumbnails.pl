#!/usr/bin/perl -w
use strict;

use JSON;
use DBI;
use URI::Escape;
use Image::Magick::Thumbnail;
use List::Util qw(shuffle);

my $root_path = "/www/kiffingish.com";
my $doc_dir = "docs";
my $img_dir = "images";
my $thumbnails_dir = "thumbnails";

my $doc_path ="$root_path/$doc_dir";
my $img_path = "$doc_path/$img_dir";
my $thumbnails_path = "$doc_path/$thumbnails_dir";
my $max_width = 100;

my $thumbnails_json = "$doc_path/thumbnails.json";

my %images;

# Ensure that the resize directory exists.
unless (-d $thumbnails_path) {
    mkdir $thumbnails_path or die "Cannot create directory: $thumbnails_path ($!)\n";
}

my $dbh = DBI->connect('dbi:mysql:mt','mt','W4LVh8EdaLXLa568') or die "Connection Error: $DBI::errstr\n";

opendir(DIR, $img_path) or die "cannot open directory: '$img_path'";

my @files = grep(/jpg|png|gif|jpeg/i, readdir(DIR));
@files = shuffle(@files);
foreach my $file (@files) {
#foreach my $file (sort grep(/jpg|png|gif|jpeg/i, readdir(DIR))) {
    my $sql = "select entry_authored_on, entry_basename, entry_title from mt_entry where entry_blog_id = 1 and entry_class = 'entry' and entry_status = 2 and entry_text like '" . '%' . $file . '%' . "'";
    my $sth = $dbh->prepare($sql);
    $sth->execute or die "SQL Error: $DBI::errstr" . "\$sql='$sql'" . "\n";
    my @entries;
    while (my @row = $sth->fetchrow_array) {
        my ($authored_on, $basename, $title) = @row;
        my ($year, $month, $dummy) = split(/\-/, $authored_on);
        $basename =~ s/_/-/g;
        my $url = "$year/$month/$basename.html";
        my $html = "$doc_path/$url";
        if (-e $html) {
            push(@entries, join("|", $title, $url));
        }
    }
    next unless @entries;
    $images{$file} = \@entries;
}

$dbh->disconnect();

my %data;

$data{thumbnails_dir} = $thumbnails_dir;
$data{img_dir} = $img_dir;
$data{max_width} = $max_width;

my $geometry = "${max_width}x${max_width}";

while( my( $file, $value ) = each %images ){
    my $src = Image::Magick->new;
    my $img;
    $src->Read("$img_path/$file");
    my ($thumb, $x, $y) = Image::Magick::Thumbnail::create($src, $geometry);
    my $thumbnail = "$thumbnails_path/$file";
    $thumb->Write($thumbnail);
    $file = uri_escape($file);
#    print "file=$file|x=${x}|y=${y}\n";
    $img->{name} = $file;
    $img->{x} = $x;
    $img->{y} = $y;
    my @entries = @{$value};
    my $cnt = 0;
    for my $entry (@entries) {
        $cnt++;
        my $ent;
        my ($title, $url) = split(/\|/, $entry);
        $ent->{title} = $title;
        $ent->{url} = $url;
#        print "$cnt: title=$title|url=$url\n";
        push(@{$img->{entries}}, $ent);
    }
    push(@{$data{images}}, $img);
}

@{$data{images}} = shuffle(@{$data{images}});

open my $fh, ">", $thumbnails_json or die "Cannot open file '$thumbnails_json' ($!)";
print $fh to_json(\%data, { utf8 => 1, pretty => 1 } );
close $fh;

# --------------------------------------------------------------------------
# $.getJSON("http://www.kiffingish.com/thumbnails.json", function(data){
#     var max_width = data.max_width;
#     var img_dir = data.img_dir;
#     var thumbnails_dir = data.thumbnails_dir;
#     $.each(data.images, function(i, field){
#         // field.x = image width, field.y = image height
#         // field.entries = array blog entries containing image
#         // entries[n].title = blog title
#         // entries[n].url = blog url
#     });
# });
# --------------------------------------------------------------------------
