#!/usr/bin/perl -w

use strict;
use Time::Local::Extended;

use Test::More 'no_plan';

my $is_leap = \&Time::Local::Extended::is_leap;

my %tests = (
    2000        => 1,
    2001        => 0,
    2002        => 0,
    2003        => 0,
    2004        => 1,
    2005        => 0,
    2008        => 1,
    2012        => 1,
    2100        => 0,
    2300        => 0,
    2400        => 1,
    2401        => 0,
    2404        => 1,
);

while( my($year, $leap) = each %tests ) {
    is !!$is_leap->($year), !!$leap, "is_leap($year)";
}
