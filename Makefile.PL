use ExtUtils::MakeMaker;

WriteMakefile
(
    'NAME'         => 'Time::Local::Extended',
    'VERSION_FROM' => 'Extended.pm',
    'PREREQ_PM'    => {
        'Time::Local' => 0,
    },
    (
        $] >= 5.005 ?
        (
            ABSTRACT_FROM => 'Extended.pm',
            AUTHOR        => 'Bob O\'Neill <bobo@cpan.org>',
        ) : ()
    ),
);
