# Time::Local::Extended -- Extends 2038 barrier to 2098.
# 
# Copyright (C) 2003-2004  Bob O'Neill.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

package Time::Local::Extended;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;
use Carp qw(cluck);
use Time::Local qw();

@ISA         = qw(Exporter);
@EXPORT      = qw(timelocal localtime timegm gmtime);
@EXPORT_OK   = qw(timelocal localtime timegm gmtime
                  UNIX_TIMESTAMP FROM_UNIXTIME);
%EXPORT_TAGS = (ALL => [qw(timelocal localtime timegm gmtime
                UNIX_TIMESTAMP FROM_UNIXTIME)] );
$VERSION     = '0.47';
local $^W    = 1;

sub timelocal
{
    my @time_data = @_;

    # Follow the Time::Local::timelocal conventions:
    #
    # 1) Treat years greater than 999 as the actual 4-digit year
    #    (not an offset from 1900)
    # 2) Treat years in the range 0..99 as years in the "current century"
    #
    my $year  = $time_data[5];
    $time_data[5] -= 1900 if $year > 999;

    if ($year >= 0 and $year <= 99)
    {
        my $current_year    = (CORE::localtime())[5] + 1900;
        my $current_century = int ($current_year / 100) * 100;
 
        my $break_point = $current_year + 50;
           $current_century += 100 if ($break_point % 100) < 50;

        my $adjusted_year  = $current_century + $year;
           $adjusted_year -= 100 if ($year + $current_century) > $break_point;

        $time_data[5] = $adjusted_year - 1900;
    }

    my $can_adjust = ($time_data[5] >= 198) ? 0 : 1;
    if (not $can_adjust)
    {
        # Just give it to timelocal as-is (not what you want, but better than
        # dying -- although in the most recent versions of Time::Local, it
        # croaks anyway).
        cluck qq|INVALID TIME ARRAY (|
                .join(',',@time_data)
                .qq|).  Giving it straight to |
                .qq| Time::Local::timelocal() and returning|;

        return Time::Local::timelocal(@time_data);
    }

    # Need to adjust if year is 2038 or greater, even in January, because
    # Time::Local::timelocal() breaks at Jan 1 2038 rather than Jan 18, 2038.
    my $adjusting = ($time_data[5] >= 138) ? 1 : 0;

    # 1) Subtract 60 years
    my $num_years = 60;
    my @adjusted_time = @time_data;
    if ($adjusting)
    {
        $adjusted_time[5] -= $num_years;

        # No need to adjust weekday here, because timelocal()
        # doesn't need weekday in order to compute the number of
        # epoch seconds.
    }

    # 2) Invoke classic timelocal
    my $timelocal = Time::Local::timelocal(@adjusted_time);

    # 3) Add 60 years worth of seconds
    #   (this is leap-year friendly since we're doing manipulations mid-century)
    my $num_seconds = 86400 * (($num_years/4) * 366 + ($num_years * 3/4) * 365);
    if ($adjusting)
    {
        $timelocal += $num_seconds;
    }

    return $timelocal;
}

sub localtime
{
    my $time_in_seconds = shift;
       $time_in_seconds = time if not defined $time_in_seconds;

    # 1) Subtract 60 years worth of seconds from time_in_seconds
    #   (this is leap-year friendly since we're doing manipulations mid-century)
    my $num_years   = 60;
    my $num_seconds = 86400 * (($num_years/4) * 366 + ($num_years * 3/4) * 365);
    my $can_adjust  = ($time_in_seconds >= 2**31 + $num_seconds) ? 0 : 1;
    if (not $can_adjust)
    {
        # Just give it to localtime as-is (not what you want, but better than
        # dying).
        cluck qq|INVALID TIME '$time_in_seconds'.  |
                .qq|Giving it straight to CORE::localtime() and returning|;
        return wantarray ? CORE::localtime($time_in_seconds)
                         : scalar CORE::localtime $time_in_seconds;
    }
    my $adjusting      = ($time_in_seconds >= 2**31) ? 1 : 0;
    my $adjusted_time  =  $time_in_seconds;
       $adjusted_time -=  $num_seconds if $adjusting;

    # 2) Invoke classic localtime
    #   (Handle both list and scalar contexts.)
    my @localtime = localtime($adjusted_time);
    my $localtime = scalar localtime($adjusted_time);

    # 3) Add 60 years to localtime return values
    if (wantarray)
    {
        if ($adjusting)
        {
            $localtime[5] += $num_years;

            # Need to adjust weekday also.
            my $weekday_adjust = ($num_years + $num_years / 4) % 7;
            my $weekday        = $localtime[6];
            my $new_weekday    = $weekday + $weekday_adjust;
               $new_weekday   -= 7 if $new_weekday > 6;
            $localtime[6]      = $new_weekday;
        }
        return @localtime;
    }
    else
    {
        if ($adjusting)
        {
            # Increment year.
            $localtime =~ s/(\d{4})$/$1+$num_years/e;

            # Compute new weekday.
            my @weekdays = qw(Sun Mon Tue Wed Thu Fri Sat);
            my %weekdays = (Sun => 0, Mon => 1, Tue => 2, Wed => 3,
                            Thu => 4, Fri => 5, Sat => 6);
            my $weekday_word     = substr $localtime, 0, 3;
            my $weekday          = $weekdays{$weekday_word};
            my $weekday_adjust   = ($num_years + $num_years / 4) % 7;
            my $new_weekday      = $weekday + $weekday_adjust;
               $new_weekday     -= 7 if $new_weekday > 6;
            my $new_weekday_word = $weekdays[$new_weekday];

            # Adjust weekday.
            $localtime =~ s/^(\w{3})/$new_weekday_word/;
        }
        return $localtime;
    }
}

sub timegm
{
    my $timelocal = &timelocal(@_);
    my $timegm    = $timelocal + &diff_to_gmt(@_);
    return $timegm;
}

sub gmtime
{
    my $gmtime    = shift;
    my $localtime = $gmtime - &diff_to_gmt(&localtime($gmtime));
    return &localtime($localtime)
}

sub UNIX_TIMESTAMP
{
    my $date_time = shift;
    my $unix_timestamp;

    my $year;
    my $month;
    my $day;
    my $hour;
    my $min;
    my $sec;
    if ($date_time =~ /^0000-?00-?00( ?00:?00:?00)?$/)
    {
            return '';
    }
    elsif ($date_time =~ /^(\d{4})-(\d{2})-(\d{2})(?: (\d{2}):(\d{2}):(\d{2}))?$/)
    {
        # DATE or DATETIME
        # "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss"
        $year  = $1;
        $month = $2;
        $day   = $3;
        $hour  = $4 || '00';
        $min   = $5 || '00';
        $sec   = $6 || '00';
    }
    elsif ($date_time =~ /^(\d{4}|\d{2})(\d{2})(\d{2})(?:(\d{2})(\d{2})(\d{2}))?$/)
    {
        # DATE or DATETIME
        # "YYYYMMDD" or "YYMMDD" or "YYYYMMDDhhmmss" or "YYMMDDhhmmss"
        $year  = $1;
        $month = $2;
        $day   = $3;
        $hour  = $4 || '00';
        $min   = $5 || '00';
        $sec   = $6 || '00';

        if ($year =~ /^\d{2}$/)
        {
            if ($year >= 0 and $year < 38)
            {
                    $year += 2000;
            }
            else
            {
                    $year += 1900;
            }
            warn "Year $year is likely to break something" if $year < 1970;
        }
    }
    else
    {
        cluck "Invalid DATE_TIME '$date_time'";
        return 0; # Epoch
    }

    my $m = $month - 1;
    my $y = $year  - 1900;
    my @localtime = ($sec, $min, $hour, $day, $m, $y);

    $unix_timestamp = &timelocal(@localtime);

    return $unix_timestamp;
}

sub FROM_UNIXTIME
{
    my $unix_timestamp = shift;

    if ($unix_timestamp eq '') ### want to warn if undef
    {
        return '0000-00-00 00:00:00';
    }
    elsif ($unix_timestamp !~ /^\d+$/)
    {
        cluck "Invalid DATE_TIME '$unix_timestamp'";
        return '0000-00-00 00:00:00';
    }

    my @localtime = &localtime($unix_timestamp);

    my $year  = $localtime[5] + 1900;
    my $month = $localtime[4] + 1;
    my $day   = $localtime[3];
    my $hour  = $localtime[2];
    my $min   = $localtime[1];
    my $sec   = $localtime[0];

    my $date_time = sprintf "%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec;

    return $date_time;
}

sub diff_to_gmt
{
    # Adjust year if necessary.
    my @t = @_;
    $t[5] -= 60 until $t[5] < 138;

    my $localtime = Time::Local::timelocal(@t);
    my $gmtime    = Time::Local::timegm(@t);
    my $gmt_diff  = ($gmtime - $localtime);

    return $gmt_diff;
}

1; # of rings to rule them all.

__END__

=head1 NAME

Time::Local::Extended - Extends 2038 barrier to 2098.

=head1 SYNOPSIS

  use Time::Local::Extended qw(:ALL);

  my @localtime   = localtime(2**31);
  my $seconds     = timelocal(0,0,0,1,10,170);
  my $gmt_seconds = timegm(0,0,0,1,10,170);
  my $gmt_time    = gmtime(2**31);
  my $ux_time     = UNIX_TIMESTAMP('2097-07-04 12:34:56');
  my $date        = FROM_UNIXTIME(2**31);

  my $sql = qq(
         SELECT start_time
         FROM   projects
         WHERE  project_id = '1'
  );
  my $date_time = $dbh->selectrow_array($sql); # '2097-07-04 12:34:56'
  my $ux_time   = UNIX_TIMESTAMP($date_time);  # 4023794096

  my $date_time = FROM_UNIXTIME(2**31);
  my $sql  = qq(
         UPDATE projects
         SET    start_time = '$date_time'
         WHERE  project_id = '1'
  );

=head1 DESCRIPTION

This module extends the 2038 date boundary to 2098.  In conventional
date manipulation using CORE::localtime and Time::Local::timelocal,
you cannot use dates later than 2038.  This module allows you
to use dates as far out as 2098, giving you sixty more years to
postpone the problem.

=head1 PUBLIC METHODS

=over 4

=item * B<timelocal>

Invoked in the same way as Time::Local::timelocal, but supports
dates up to Jan 1, 2098.

=item * B<localtime>

Invoked in the same way as CORE::localtime, but supports
dates up to Jan 18, 2098.

=item * B<timegm>

Invoked in the same way as Time::Local::timegm, but supports
dates up to Jan 1, 2098.

=item * B<gmtime>

Invoked in the same way as CORE::gmtime, but supports
dates up to Jan 18, 2098.

=item * B<UNIX_TIMESTAMP>

Invoked similarly to the MySQL UNIX_TIMESTAMP() function, but supports
dates up to Jan 1, 2098.

=item * B<FROM_UNIXTIME>

Invoked similarly to the MySQL FROM_UNIXTIME() function, but supports
dates up to Jan 18, 2098.

=back

=head1 BUGS

Please e-mail bug reports or suggestions to bobo@cpan.org.  Thanks!

=head1 TODO

  1) Trap Time::Local::timelocal die in an eval {}.
  2) Add support for timelocal_nocheck and timegm_nocheck.
  3) Add tests for time zones other than Eastern.
  4) Clean up.  Lots of clean up.

=head1 CREDITS

Thanks to Peter Kioko <ceph@techie.com> for helping to refine the idea.
Thanks to Adam Foxson <afoxson@pobox.com> for quality assurance and
for being the Human CPAN Reference Manual.

=head1 AUTHOR

Bob O'Neill, E<lt>bobo@cpan.orgE<gt>
 
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2004 Bob O'Neill.
All rights reserved.

See COPYING for license

=head1 SEE ALSO

=over 4

=item * L<perl>.

=item * L<Time::Local>.

=back

=cut
