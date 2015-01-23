# Introduction

These are all my personal perl scripts that I use for my [movable type blog][blogurl]

| Script | Description |
| -----  | ----------- |
| blogentries.pl | most popular blog entries using awstats |
| create_thumbnails.pl | scan all blog entry images and create list |
| email_me.pl | send me an email message |
| get-handicap.pl | get my current handicap as registerd on ngf |
| pingomatic.sh | blog ping pingomatic to ping other sites |
| rand-banner.pl | generate a random banner |
| rand-entry.pl | goto a random blog entry |
| rpcping2.pl | blog ping all kinds of other sites, including google |
| searchphrases.pl | most popular search phrases using awstats |
| visitors.pl | number of visitors and hits using awstats |

## Configuration

    The configuration setting are kept in the config.ini file. You will
    have to first copy the example and edit it to fit your needs.

    $ cp config.ini.example config.ini

## Usage

    git commit -a  -m "interesting message goes here ..."
    git remote add origin git@github.com:kgish/mt-perlscripts.git
    git push -u origin master

[blogurl]: http://www.kiffingish.com
