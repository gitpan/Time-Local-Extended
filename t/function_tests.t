#!/usr/bin/perl -w
use strict;

use Test::More tests => 40;
use Time::Local::Extended qw(:ALL);

# Testing of CORE:: and Time::Local:: modules can be turned on,
# but it is off by default. Certain platforms behave differently.
# If you turn $RUN_ALL_TESTS = 1, add 18 to the test plan above.
my $RUN_ALL_TESTS = 0;

# The tests are written assuming EST, so try to switch into that.
local $ENV{TZ} = "US/Eastern";

# Do not test unless we are in the Eastern time zone.
my $localtime    = Time::Local::timelocal(0,0,0,3,10,103);
my $gmtime       = Time::Local::timegm(0,0,0,3,10,103);
my $gmt_diff     = ($gmtime - $localtime) / 3600;
my $gmt_offset   = $gmt_diff * 3600;
my $eastern_diff = $gmt_diff + 5;

# Setup
my $old_limit_a = 2**31 - 1;
my $old_limit_b = $old_limit_a + 1;
my $new_limit_a = 2**31 + 86400 * 365.25 * 60 - 1;
my $old_last_timelocal = 2145934799; # End of Year 2037
my $new_last_timelocal = 4039390799; # End of Year 2097
my $old_last_timegm  =   2145916799;
my $new_last_timegm  =   4039372799;
my $new_gmtime_limit = $new_limit_a + $gmt_offset;
my $random_time_1 = 3182040000;
my $random_time_2 = 4023794096;
my $summer_time   = 4026153599;

###########
#         #
#  Tests  #
#         #
###########

# timelocal
SKIP: {
    skip "timelocal() tests specific to EST", 7 if $eastern_diff;

    is(timelocal(59,59,23,31,11,137) , $old_last_timelocal);
    is(timelocal(0,0,0,1,0,138)      , $old_last_timelocal + 1);
    is(timelocal(7,14,22,18,0,138)   , $old_limit_a);
    is(timelocal(8,14,22,18,0,138)   , $old_limit_b);
    is(timelocal(0,0,0,1,10,170)     , $random_time_1);
    is(timelocal(59,59,23,31,11,197) , $new_last_timelocal);
    is(timelocal(59,59,23,31,11,2097), $new_last_timelocal);
}

# timegm
{
    is(timegm(59,59,23,31,11,137), $old_last_timegm);
    is(timegm(0,0,0,1,0,138)     , $old_last_timegm + 1);
    is(timegm(7,14,3,19,0,138)   , $old_limit_a);
    is(timegm(8,14,3,19,0,138)   , $old_limit_b);
    is(timegm(0,0,4,1,10,170)    , $random_time_1);
    is(timegm(59,59,23,31,11,197), $new_last_timegm);
    is(timegm(59,59,23,31,6,197) , $summer_time);
}

# localtime
SKIP: {
    skip "localtime() tests specific to EST", 8 if $eastern_diff;

    is(join ('|',localtime(0)) , '0|0|19|31|11|69|3|364|0');
    is(scalar localtime(0)     , 'Wed Dec 31 19:00:00 1969');

    is(join ('|',localtime($old_limit_a)) , '7|14|22|18|0|138|1|17|0');
    is(scalar localtime($old_limit_a)     , 'Mon Jan 18 22:14:07 2038');

    is(join ('|',localtime($old_limit_b)) , '8|14|22|18|0|138|1|17|0');
    is(scalar localtime($old_limit_b)     , 'Mon Jan 18 22:14:08 2038');

    is(join ('|',localtime($new_limit_a)) , '7|14|22|18|0|198|6|17|0');
    is(scalar localtime($new_limit_a)     , 'Sat Jan 18 22:14:07 2098');
}

# gmtime
{
    is(join ('|',gmtime(0)) , '0|0|0|1|0|70|4|0|0');
    is(scalar gmtime(0)     , 'Thu Jan  1 00:00:00 1970');

    is(join ('|',gmtime($old_limit_a)) , '7|14|3|19|0|138|2|18|0');
    is(scalar gmtime($old_limit_a)     , 'Tue Jan 19 03:14:07 2038');

    is(join ('|',gmtime($old_limit_b)) , '8|14|3|19|0|138|2|18|0');
    is(scalar gmtime($old_limit_b)     , 'Tue Jan 19 03:14:08 2038');

    is(join ('|',gmtime($new_gmtime_limit)) , '7|14|22|18|0|198|6|17|0');
    is(scalar gmtime($new_gmtime_limit)     , 'Sat Jan 18 22:14:07 2098');

    is(scalar gmtime($summer_time) , 'Wed Jul 31 23:59:59 2097');
}

# UNIX_TIMESTAMP

SKIP: {
    skip "UNIX_TIMESTAMP() tests specific to EST", 6 if $eastern_diff;    

    is(UNIX_TIMESTAMP('1970-01-01 00:00:00'), 3600 * 5);
    is(UNIX_TIMESTAMP('2038-01-18 22:14:07'), $old_limit_a);
    is(UNIX_TIMESTAMP('2038-01-18 22:14:08'), $old_limit_b);
    is(UNIX_TIMESTAMP('2097-07-04 12:34:56'), $random_time_2);
    is(UNIX_TIMESTAMP('2097-12-31 23:59:59'), $new_last_timelocal);
    is(UNIX_TIMESTAMP('1969-12-31 19:00:00'), 0);
} 

# FROM_UNIXTIME

SKIP: {
    skip "FROM_UNIXTIME() tests specific to EST", 3 if $eastern_diff;

    is(FROM_UNIXTIME($old_limit_a) , '2038-01-18 22:14:07');
    is(FROM_UNIXTIME($old_limit_b) , '2038-01-18 22:14:08');
    is(FROM_UNIXTIME($new_limit_a) , '2098-01-18 22:14:07');
}

# Testing of CORE:: and Time::Local::
if ($RUN_ALL_TESTS)
{
    # localtime
    SKIP: {
        skip "localtime() tests specific to EST", 9 if $eastern_diff;

        is(join ('|',CORE::localtime(0)) , '0|0|19|31|11|69|3|364|0');
        is(scalar CORE::localtime(0)     , 'Wed Dec 31 19:00:00 1969');
        is(join ('|',CORE::localtime($old_limit_a)) , '7|14|22|18|0|138|1|17|0');
        is(scalar CORE::localtime($old_limit_a)     , 'Mon Jan 18 22:14:07 2038');
        is(join ('|',CORE::localtime($old_limit_b)) , '52|45|15|13|11|1|5|346|0');
        is(scalar CORE::localtime($old_limit_b)     , 'Fri Dec 13 15:45:52 1901');
        is(join ('|',CORE::localtime($new_limit_a)) , '51|45|15|13|11|37|1|346|0');
        is(scalar CORE::localtime($new_limit_a)     , 'Mon Dec 13 15:45:51 1937');

        is(Time::Local::timelocal(59,59,23,31,11,137), $old_last_timelocal);
    }

    # gmtime
    {
        is(join ('|',CORE::gmtime(0)) , '0|0|0|1|0|70|4|0|0');
        is(scalar CORE::gmtime(0)     , 'Thu Jan  1 00:00:00 1970');

        is(join ('|',CORE::gmtime($old_limit_a)) , '7|14|3|19|0|138|2|18|0');
        is(scalar CORE::gmtime($old_limit_a)     , 'Tue Jan 19 03:14:07 2038');

        is(join ('|',CORE::gmtime($old_limit_b)) , '52|45|20|13|11|1|5|346|0');
        is(scalar CORE::gmtime($old_limit_b)     , 'Fri Dec 13 20:45:52 1901');

        is(join ('|',CORE::gmtime($new_gmtime_limit)) , '51|45|15|13|11|61|3|346|0');
        is(scalar CORE::gmtime($new_gmtime_limit)     , 'Wed Dec 13 15:45:51 1961');
    }

    # timelocal
    is(Time::Local::timegm(59,59,23,31,11,137), $old_last_timegm);
}
