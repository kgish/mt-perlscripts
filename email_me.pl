#!/usr/bin/perl

use strict;
use warnings;

# CPAN modules
use CGI qw( :standard );
use CGI::Carp qw( fatalsToBrowser );
use DB_File;
#use Mail::Sendmail qw(sendmail %mailcfg);
use Mail::Sendmail qw(sendmail);

use constant MAX_TM  => 24 * (60 * 60); # 1 day.
use constant MAX_CNT => 3;
#use constant MAX_URLS => 1;
use constant MAX_URLS => 0;
use constant FILE_DB => 'email_me.db';
use constant MAILHOST => 'mail.leaseweb.nl';

my ($first_name, $last_name, $email_me) = ('Kiffin', 'Gish', 'kiffin.gish@planet.nl');

my %db_hash;
tie %db_hash, 'DB_File', FILE_DB, O_CREAT|O_RDWR, 0666, or die_with_email( "Cannot create/open file '" . FILE_DB . "': $!");

my $name = param('name');
my $email = param('email');
my $message = param('message');
my $redirect = param('redirect');
my $css = param('css');
my $mailhost = param('mailhost') || MAILHOST;

my $email_from = "$name <$email>";

my $ip_addr = remote_host();
my $server_name = server_name();
my $referer = referer();
my $user_agent = user_agent();
my $nr_urls = count_substrings($message, 'https?:/');
my $is_spam = (($referer !~ /$server_name/)?1:0);
$is_spam = (($nr_urls>MAX_URLS)?1:$is_spam);
my $tm1 = time();
my ($tm0, $cnt) = (0, 0);

if ($db_hash{$ip_addr}) {
    ($tm0, $cnt) = split('\|\|\|', $db_hash{$ip_addr});
}

if ($tm0)
{
    # Has recently sent email at least once.
    $cnt++;
    $db_hash{$ip_addr} = "$tm0|||$cnt";
    if ($cnt > MAX_CNT) {
        if ($tm1 - $tm0 < MAX_TM) {
            # Too many emails within maximum period.
            print header;
            print start_html( -title => 'You must wait',
                              -style => { src => $css },            
            );
            print h2('Too many emails sent');
            print p('Sorry, but you have already sent me ' . MAX_CNT . ' email messages today. Please wait until tomorrow if you really want to send me more.');
            print end_html;

            # Bye-bye.
            exit;
        }
        else {
            # Reset counter to beginning.
            $cnt = 1;
        }
    }
} else {
    # First time
    $cnt = 1;
}

$db_hash{$ip_addr} = "$tm1|||$cnt";

# --- Email notification to me --- #

my $email_to = "$first_name $last_name <$email_me>";

my $subject = "[kiffingish.com] Email message from $name ($ip_addr) ...";

my $email_message = <<"EMAIL";
[--- This is an automated email notification ---]

Dear $first_name $last_name,

Congratulations! A visitor to Kiffingish.com has decided to send you a personal email message.

name: $name
email: $email
ip: $ip_addr
server_name: $server_name
referer: $referer
user_agent: $user_agent
nr_urls: $nr_urls
is_spam: $is_spam

--start--
$message
--end--

Just thought you might be interested.

EMAIL

my %mail = (
    To      => $email_to,
    From    => $email_from,
    Subject => $subject,
    Message => $email_message,
);

#$mailcfg{smtp} = [ $mailhost ];

if (!$is_spam) {
    # Only if not spam.
    sendmail(%mail) or die( "Cannot send email, from='$email_from', to='$email_to' : $Mail::Sendmail::error\n" );
}   

# --- Email thanks to sender --- #

$subject = "[kiffingish.com] Thanks $name for your email message ...";

$email_message = <<"EMAIL";
Dear $name,

Just wanted to thank you for having visited Kiffingish.com and taking the time to send me an email message.

For me it is always a pleasant surprise hearing from my readers in person.

Please feel free to drop by again anytime.

Kind regards,
Kiffin

----------

This was your email message:

$message

EMAIL

($email_from, $email_to) = ($email_to, $email_from);

%mail = (
    To      => $email_to,
    From    => $email_from,
    Subject => $subject,
    Message => $email_message,
);

#$mailcfg{smtp} = [ $mailhost ];

if (!$is_spam) {
    # Only if not spam.
    sendmail(%mail) or die( "Cannot send email, from='$email_from', to='$email_to' : $Mail::Sendmail::error\n" );
}

print redirect($redirect);

sub count_substrings {
    my ($str, $m) = @_;
    my $n = 0;
    my @lines = split('\n', $str);
    for my $line (@lines) {
        $n++ while ($line =~ /$m/gi);
    }
    return $n;
}

sub die_with_email {
    my $errmsg = shift;
    
    my $subject = "[kiffingish.com] An error has occurred ...";

    my $email_to = "$first_name $last_name <$email_me>";
    my $email_from = $email_to;

    my $email_message = <<"EMAIL";
[--- This is an automated email notification ---]

Dear $first_name $last_name,

Oops, it looks like an error has occurred in the email_me.pl script.

--start--
$errmsg
--end--

Just thought you might be interested.

EMAIL

    %mail = (
        To      => $email_to,
        From    => $email_from,
        Subject => $subject,
        Message => $email_message,
    );

    #$mailcfg{smtp} = [ $mailhost ];

    sendmail(%mail);

    die ("$errmsg\n");
}
