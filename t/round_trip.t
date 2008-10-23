#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

use Time::Local::Extended qw(:ALL);

# Edge case times to test.
my @times = (2**44, 2**38, 2**37, 2**33, 2**31, 2**30, 1, 0, time, int rand 2**33);
# And negatives
push @times, map { -$_ } @times;

ok 1==1;

#    for my $time (@times) {
#        {
#            my @date = localtime($time);
#            $date[5] += 1900;
#            is timelocal( @date ), $time, "timelocal(@date) / localtime($time)";
#            
#        }
#
#        {
#            my @date = gmtime($time);
#            print "# Year: $date[5]\n";
#            $date[5] += 1900;
#            is timegm( @date ), $time, "timegm(@date) / gmtime($time)";
#        }
#
#        {
#            my $stamp = FROM_UNIXTIME($time);
#            is UNIX_TIMESTAMP($stamp), $time, "FROM_UNIXTIME($time) / UNIX_TIMESTAMP($stamp)";
#        }
#    }
