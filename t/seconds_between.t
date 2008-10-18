#!/usr/bin/perl -w

use strict;
use Time::Local::Extended;

use Test::More 'no_plan';

my $seconds_between = \&Time::Local::Extended::seconds_between;
my $secs_per_day    = 60 * 60 * 24;
my @tests = (
    [2000, 2000, 0],
    [2001, 2000, $secs_per_day*366],
    [2004, 2000, ($secs_per_day * 365 * 3) + ($secs_per_day * 366)],
    [2005, 2000, ($secs_per_day * 365 * 3) + ($secs_per_day * 366 * 2)],
);

for my $test ( @tests ) {
    my($orig, $safe, $seconds) = @$test;
    is $seconds_between->($orig, $safe), $seconds, "seconds_between($orig, $safe)";
}

