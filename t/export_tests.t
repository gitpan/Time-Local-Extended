#!/usr/bin/perl -w

use Test::More;

use strict;
use Time::Local::Extended;

local $^W = 1; # warnings on, compatible with old Perls

# The purpose of these tests is to show that these functions
# are exported by default.

# SETUP
local $ENV{TZ} = "US/Eastern";
my $localtime    = Time::Local::timelocal(0,0,0,3,10,103);
my $gmtime       = Time::Local::timegm(0,0,0,3,10,103);
my $gmt_diff     = ($gmtime - $localtime) / 3600;
my $eastern_diff = $gmt_diff + 5;
my $gmt_offset   = $gmt_diff * 3600;
my $new_last_timelocal = 4039390799; # End of Year 2098
my $new_last_timegm    = $new_last_timelocal + $gmt_offset;

if ($eastern_diff) {
    plan skip_all => "Tests require eastern time zone";
}
else {
    plan tests => 4;
}


# TEST
ok (timelocal(59,59,23,31,11,197)  == $new_last_timelocal);
ok (timegm(59,59,23,31,11,197) == $new_last_timegm);
ok (scalar localtime($new_last_timelocal) eq 'Tue Dec 31 23:59:59 2097');
ok (scalar gmtime($new_last_timegm)       eq 'Tue Dec 31 23:59:59 2097');

