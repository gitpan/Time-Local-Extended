use ExtUtils::MakeMaker;
use Config;

# To be portable.
my $objext = $Config{obj_ext};

die "\$Config{quadtype} must be defined for this module to work."
  unless $Config{quadtype};

WriteMakefile
(
    'NAME'         => 'Time::Local::Extended',
    'VERSION_FROM' => 'lib/Time/Local/Extended.pm',
    'PREREQ_PM'    => {
        'Time::Local' => 0,
    },
    OBJECT => "time64$objext Extended$objext",

    PL_FILES => {
        "munge_config" => "time64_config.h"
    },

    (
        $] >= 5.005 ?
        (
            ABSTRACT_FROM => 'lib/Time/Local/Extended.pm',
            AUTHOR        => 'Bob O\'Neill <bobo@cpan.org>',
        ) : ()
    ),

    clean => {
        FILES   => "time64_config.h"
    },
);

{
    package MY;

    sub MY::postamble {
        return <<"MAKE";
time64$objext : time64_config.h

MAKE
    }
}
