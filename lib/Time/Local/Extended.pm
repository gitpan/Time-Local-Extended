package Time::Local::Extended;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;
use DynaLoader;
use Carp qw(cluck);
use Time::Local qw();

@ISA         = qw(Exporter DynaLoader);
@EXPORT      = qw(timelocal localtime timegm gmtime);
@EXPORT_OK   = qw(UNIX_TIMESTAMP FROM_UNIXTIME);
%EXPORT_TAGS = (ALL => [@EXPORT, @EXPORT_OK]);
$VERSION     = '0.51';
local $^W    = 1;

bootstrap Time::Local::Extended $VERSION;

# Follow the Time::Local::timelocal conventions:
#
# 1) Treat years greater than 999 as the actual 4-digit year
#    (not an offset from 1900)
# 2) Treat years in the range 0..99 as years in the "current century"
sub munge_year {
    my $year  = shift;

    return $year - 1900 if $year > 999 or $year < 0;

    if ($year >= 0 and $year <= 99)
    {
        my $current_year    = (CORE::localtime())[5] + 1900;
        my $current_century = int ($current_year / 100) * 100;
 
        my $break_point = $current_year + 50;
           $current_century += 100 if ($break_point % 100) < 50;

        my $adjusted_year  = $current_century + $year;
           $adjusted_year -= 100 if ($year + $current_century) > $break_point;

        return $adjusted_year - 1900;
    }

    return $year;
}

sub timelocal
{
    my @time_data = @_;

    $time_data[5] = munge_year($time_data[5]);

    # Need to adjust if year is 2038 or greater, even in January, because
    # Time::Local::timelocal() breaks at Jan 1 2038 rather than Jan 18, 2038.
    # Also if the year is at or before 1970 because negative times often don't
    # work.
    my $adjusting = ($time_data[5] >= 138 or $time_data[5] <= 70) ? 1 : 0;
    my $num_years = 0;

    my $orig_year;
    my $safe_year;
    my @adjusted_time = @time_data;
    if ($adjusting)
    {
        $orig_year = $time_data[5] + 1900;
        $safe_year = safe_year($orig_year);
        $num_years = $orig_year - $safe_year;
        $adjusted_time[5] = $safe_year;

        # No need to adjust weekday here, because timelocal()
        # doesn't need weekday in order to compute the number of
        # epoch seconds.
    }

    # 2) Invoke classic timelocal
    my $timelocal = Time::Local::timelocal(@adjusted_time);

    # 3) Add enough seconds to get back
    if( $adjusting ) {
        $timelocal += seconds_between($orig_year, $safe_year);
    }

    return $timelocal;
}


my $days_in_cycle = (365 * 400) + 100 - 4 + 1;
sub seconds_between {
    my($orig, $safe) = @_;

    my $increment = ( $orig > $safe ) ? 1 : -1;
    my $seconds = 0;

    if( $orig > 2400 ) {
        my $cycles = int(($orig - 2400) / 400);
        $orig -= $cycles * 400;
        $seconds += $cycles * $days_in_cycle * 60 * 60 * 24;
    }

    until( $safe == $orig ) {
        my $days = is_leap($safe) ? 366 : 365;
        $seconds += $days * 60 * 60 * 24;
        $safe += $increment;
    }

    return $seconds * $increment + 0; # We prefer 0 to -0.
}


sub is_leap {
    my $year = shift;
    return 1 if $year % 400 == 0;
    return 0 if $year % 100 == 0;
    return 1 if $year % 4   == 0;
}


my @Day_Names   = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
my @Month_Names = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

for my $func (qw(localtime gmtime)) {
    my $func64 = do {
        no strict 'refs';
        \&{$func . "64"};
    };

    my $code = sub {
        my $time = @_ ? shift : time;

        my @date = $func64->($time);
        return @date if wantarray;
        return sprintf "%s %s %2d %02d:%02d:%02d %.0f",
          $Day_Names[$date[6]], $Month_Names[$date[4]], $date[3],
          $date[2], $date[1], $date[0],
          $date[5] + 1900;
    };
    
    no strict 'refs';
    *{$func} = $code;
}

sub timegm
{
    my @date = @_[0..5];
    $date[5] = munge_year($date[5]);

    return timegm64(@date);
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
    elsif ($date_time =~ /^(-?\d{4,})-(\d{2})-(\d{2})(?: (\d{2}):(\d{2}):(\d{2}))?$/)
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
    elsif ($date_time =~ /^(-?\d{4,}|-?\d{2})(\d{2})(\d{2})(?:(\d{2})(\d{2})(\d{2}))?$/)
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

    my $m = $month - 1;
    my @localtime = ($sec, $min, $hour, $day, $m, $year);

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
    elsif ($unix_timestamp !~ /^-?\d+$/)
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

1; # of rings to rule them all.

__END__

=head1 NAME

Time::Local::Extended - Increase the range of localtime and timelocal

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
         FROM   project
         WHERE  id = 1
  );
  my $date_time = $dbh->selectrow_array($sql); # '2097-07-04 12:34:56'
  my $ux_time   = UNIX_TIMESTAMP($date_time);  # 4023794096

  my $date_time = FROM_UNIXTIME(2**31);
  my $sql  = qq(
         UPDATE project
         SET    start_time = ?
         WHERE  id = 1
  );
  $dbh->do($sql, undef, $date_time);

=head1 DESCRIPTION

This module extends the date range of localtime(), gmtime(), timegm()
and timelocal() to go safely beyond 2038 and before 1970 on any
operating system.

It also provides a handful of useful time conversion functions.


=head1 PUBLIC FUNCTIONS

=over 4

=item * B<timelocal>

Invoked in the same way as Time::Local::timelocal().

=item * B<localtime>

Invoked in the same way as CORE::localtime().

=item * B<timegm>

Invoked in the same way as Time::Local::timegm().

=item * B<gmtime>

Invoked in the same way as CORE::gmtime().

=item * B<UNIX_TIMESTAMP>

Invoked similarly to the MySQL UNIX_TIMESTAMP() function()

=item * B<FROM_UNIXTIME>

Invoked similarly to the MySQL FROM_UNIXTIME() function()

=back

=head1 LIMITATIONS

Because of the way timegm() and timelocal() try to Do What You Mean
with the year, it is impossible to feed it the years 0 through 99 (it
thinks you mean 2000 - 2099).

While the code can in theory go out to 2**63, the practical portable
limit of this code is from 2**52 to -2**52 (the limit of double
floating point precision) after which precision starts to drop off.
This gives you a range of about +/- 142 million years.

=head1 BUGS

Doesn't correctly handle British Summer Time 1968-1971

Please e-mail bug reports or suggestions to bobo@cpan.org.  Thanks!

=head1 CREDITS

Thanks to Michael Schwern for extending this module's capabilities
beyond 2098.

Thanks to Peter Kioko for helping to refine the idea, and Adam Foxson,
the Human CPAN Reference Manual, for quality assurance.

=head1 AUTHOR

Bob O'Neill, E<lt>bobo@cpan.orgE<gt>
 
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2008 Bob O'Neill and Michael Schwern.
All rights reserved.

See COPYING for license

=head1 SEE ALSO

=over 4

=item * L<perl>.

=item * L<Time::Local>.

=back

=cut
