use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Test::WWW::Mechanize::Runner',
    VERSION_FROM => 'lib/Test/WWW/Mechanize/Runner.pm',
    PREREQ_PM => {
        'WWW::Mechanize' => 0,
    },
    ABSTRACT => 'test-suites maker for "WWW::Mechanize"-compatible agents',
    test => {TESTS => join( ' ', glob( 't/*.t' ))},
);
