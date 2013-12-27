#!/usr/bin/perl -w
use strict;

use JSON;
use DBI;
use URI::Escape;
use Image::Magick::Thumbnail;
use List::Util qw(shuffle);

use Config::IniFiles;
my $cfg = Config::IniFiles->new( -file => "config.ini" );

my $root_path = $cfg->val( 'create_thumbnails', 'root_path' );
my $doc_dir = $cfg->val( 'create_thumbnails', 'doc_dir' );
my $img_dir = $cfg->val( 'create_thumbnails', 'img_dir' );
my $thumbnails_dir = $cfg->val( 'create_thumbnails', 'thumbnails_dir' );
my $debug = $cfg->val( 'create_thumbnails', 'debug' );

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

my $dbi = $cfg->val( 'create_thumbnails', 'dbi' );
my $dbname = $cfg->val( 'create_thumbnails', 'dbname' );
my $dbuser = $cfg->val( 'create_thumbnails', 'dbuser' );
my $dbpasswd = $cfg->val( 'create_thumbnails', 'dbpasswd' );

my $dbh = DBI->connect("dbi:${dbi}:${dbname}",$dbuser,$dbpasswd) or die "Connection Error: $DBI::errstr\n";

opendir(DIR, $img_path) or die "cannot open directory: '$img_path'";

my @files = grep(/jpg|png|gif|jpeg/i, readdir(DIR));
print "Readdir: " . (scalar @files) . " files\n" if $debug;
@files = shuffle(@files);
foreach my $file (@files) {
#foreach my $file (sort grep(/jpg|png|gif|jpeg/i, readdir(DIR))) {
    my $sql = "select entry_authored_on, entry_basename, entry_title from mt_entry where entry_blog_id = 1 and entry_class = 'entry' and entry_status = 2 and entry_text like '" . '%' . $file . '%' . "'";
    if ($file =~ /-thumb-/) {
      print "\$file='$file' => IGNORE!\n" if $debug;
      next;
    }
    print "\$file='$file'\n" if $debug;
    # print "\$sql='$sql'\n";
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
            print "\$title='$title',\$url='$url'\n" if $debug;
            push(@entries, join("|", $title, $url));
        }
    }
    next unless @entries;
    $images{$file} = \@entries;
}
print "Done: files\n" if $debug;

$dbh->disconnect();

my %data;

$data{thumbnails_dir} = $thumbnails_dir;
$data{img_dir} = $img_dir;
$data{max_width} = $max_width;

my $geometry = "${max_width}x${max_width}";

print "Each images\n" if $debug;
my $num = 0;
while( my( $file, $value ) = each %images ){
    $num++;
    print "$num: \$file='$file\n" if $debug;
    my $src = Image::Magick->new;
    my $img;
    $src->Read("$img_path/$file");
    my ($thumb, $x, $y) = Image::Magick::Thumbnail::create($src, $geometry);
    my $thumbnail = "$thumbnails_path/$file";
    $thumb->Write($thumbnail);
    $file = uri_escape($file);
    print "\$file='$file',\$x=${x}, \$y=${y}\n" if $debug;
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
        print "$cnt: \$title='$title',\$url='$url'\n" if $debug;
        push(@{$img->{entries}}, $ent);
    }
    print "Push\n" if $debug;
    push(@{$data{images}}, $img);
}

print "Shuffle: before\n" if $debug;
@{$data{images}} = shuffle(@{$data{images}});
print "Shuffle: after\n" if $debug;

print "Open: before\n" if $debug;
open my $fh, ">", $thumbnails_json or die "Cannot open file '$thumbnails_json' ($!)";
print $fh to_json(\%data, { utf8 => 1, pretty => 1 } );
close $fh;
print "Open: after\n" if $debug;

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
