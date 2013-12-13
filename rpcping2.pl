#!/usr/bin/perl -w
#
# rpcping.pl - Ping your blog with update services
#
# © Copyright, 2006 by John Bokma, http://johnbokma.com/
# License: The Artistic License
#
# $Id: rpcping.pl 1083 2008-09-30 19:06:18Z john $ 

use strict;
use warnings;

use XMLRPC::Lite;

sub print_usage_and_exit {

    print <<USAGE;
usage: rpcping.pl "YOUR WEBLOG NAME" URL
USAGE

    exit;
}

@ARGV == 2 or print_usage_and_exit;
my ( $blog_name, $blog_url ) = @ARGV;

my @services = (

    # See http://codex.wordpress.org/Update_Services for
    # a more comprehensive list.
    'Google'         => 'http://blogsearch.google.com/ping/RPC2',
    'Weblogs.com'    => 'http://rpc.weblogs.com/RPC2',
    'Feed Burner'    => 'http://ping.feedburner.com/',
    'Moreover'       => 'http://api.moreover.com/RPC2',
    'Syndic8'        => 'http://ping.syndic8.com/xmlrpc.php' ,
    'BlogRolling'    => 'http://rpc.blogrolling.com/pinger/',
    'Technorati'     => 'http://rpc.technorati.com/rpc/ping' ,
    'BulkFeeds'      => 'http://bulkfeeds.net/rpc',
    'BlogFlux'       => 'http://pinger.blogflux.com/rpc/',
    'Ping-o-Matic!'  => 'http://rpc.pingomatic.com/',
    'NewsGator'      => 'http://services.newsgator.com/ngws/xmlrpcping.aspx',
    'Blog People'    => 'http://www.blogpeople.net/servlet/weblogUpdates',
    'Howly Cow Dude' => 'http://www.holycowdude.com/rpc/ping/',
    'Blog Update'    => 'http://blogupdate.org/ping/',
    'FeedSky'        => 'http://www.feedsky.com/api/RPC2',
);

#while ( my ( $service_name, $rpc_endpoint ) = splice @services, 0, 2 ) {
while ( <DATA> ) {
    chomp;
    my $service_name = $_;
    my $rpc_endpoint = "http://$_";

    my $xmlrpc = XMLRPC::Lite->proxy( $rpc_endpoint );
    my $call;
    eval {
        $call = $xmlrpc->call( 'weblogUpdates.ping',
            $blog_name, $blog_url );
    };
    if ( $@ ) {

        chomp $@;
        warn "Ping '$service_name' failed: '$@'\n";
        next;
    }

    unless ( defined $call ) {

        warn "Ping '$service_name' failed for an unknown reason\n";
        next;
    }

    if ( $call->fault ) {

        chomp( my $message = $call->faultstring );
        warn "Ping '$service_name' failed: '$message'\n";
        next;
    }

    my $result = $call->result;
    if ( $result->{ flerror } ) {

        warn "Ping '$service_name' returned the following error: '",
            $result->{ message }, "'\n";
        next;
    }

    print "Ping '$service_name' returned: '$result->{ message }'\n";
}

__END__
rpc.pingomatic.com
blogsearch.google.ae/ping/RPC2
blogsearch.google.at/ping/RPC2
blogsearch.google.be/ping/RPC2
blogsearch.google.bg/ping/RPC2
blogsearch.google.ca/ping/RPC2
blogsearch.google.ch/ping/RPC2
blogsearch.google.cl/ping/RPC2
blogsearch.google.co.cr/ping/RPC2
blogsearch.google.co.hu/ping/RPC2
blogsearch.google.co.id/ping/RPC2
blogsearch.google.co.il/ping/RPC2
blogsearch.google.co.in/ping/RPC2
blogsearch.google.co.jp/ping/RPC2
blogsearch.google.co.ma/ping/RPC2
blogsearch.google.co.nz/ping/RPC2
blogsearch.google.co.th/ping/RPC2
blogsearch.google.co.uk/ping/RPC2
blogsearch.google.co.ve/ping/RPC2
blogsearch.google.co.za/ping/RPC2
blogsearch.google.de/ping/RPC2
blogsearch.google.es/ping/RPC2
blogsearch.google.fi/ping/RPC2
blogsearch.google.fr/ping/RPC2
blogsearch.google.gr/ping/RPC2
blogsearch.google.hr/ping/RPC2
blogsearch.google.ie/ping/RPC2
blogsearch.google.it/ping/RPC2
blogsearch.google.jp/ping/RPC2
blogsearch.google.lt/ping/RPC2
blogsearch.google.nl/ping/RPC2
blogsearch.google.pl/ping/RPC2
blogsearch.google.pt/ping/RPC2
blogsearch.google.ro/ping/RPC2
blogsearch.google.ru/ping/RPC2
blogsearch.google.sk/ping/RPC2
blogsearch.google.us/ping/RPC2
