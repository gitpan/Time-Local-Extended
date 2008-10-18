#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

use Time::Local::Extended;

my $munge_year = \&Time::Local::Extended::munge_year;

my %tests = (
    0           => 100,
    1           => 101,
    49          => 149,
    50          => 150,
    51          => 151,
    99          => 99,
    100         => 100,
    999         => 999,
    1000        => -900,
    1999        => 99,
    2001        => 101,
    -2386       => -2386 - 1900,
    -1          => -1901,
);

while(my($year, $munged) = each %tests) {
    is $munge_year->($year), $munged, "munge_year($year)";
}
