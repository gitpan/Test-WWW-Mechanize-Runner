package Test::WWW::Mechanize::Runner;

use strict;
use warnings;
use Carp 'confess';
use base 'Exporter';
use vars qw($VERSION @EXPORT);

$VERSION = '0.0.1';
@EXPORT  = qw(suite);

# supported agents :
my $agent_module = {
    'default'     => 'WWW::Mechanize',
    'mozilla'     => 'Mozilla::Mechanize',
    'mozilla-gui' => 'Mozilla::Mechanize::GUITester',
    'msie'        => 'Win32::IE::Mechanize', 
};

# singleton & accessors
my $config = {};
sub config { $config }
sub agent  { $config->{agent} } 

# the list of defined actions
my $actions = [];
sub actions { $actions }

# The init() method instanciate the appropriate agent
# and saves it in the config hash
sub init {
    my ($class, $agent) = @_;
    $agent ||= 'default';

    confess "Agent '$agent' unsupported" 
        unless defined $agent_module->{$agent};

    # loading the agent's module
    my $module = $agent_module->{$agent};
    eval "use $module";
    confess "Unable to load agent : $agent ($module)" if $@;

    # creating the agent
    $module->import;
    $config->{agent} = new $module;
}

sub suite {
    my ($name, $sub) = @_;
    my $caller = caller;

    # make sure the action is not yet defined
    confess "Action '$name' already defined" 
        if grep /^$name$/, map { $_->{name} } @$actions;

    # redefine the action
    my $sub_coderef = sub {
        print "# running test-suite: \"$name\"\n";

        # make sure the test session is initialized
        # before loading the test suite
        $caller->init() unless defined $caller->agent;

        # actually runs the test suite, passing the agent in argument
        $sub->($caller->agent);
    };

    # save the action
    push @$actions, { name => $name, code => $sub_coderef };

    # define the action in the namespace
    my $sub_name = "${caller}::${name}";
    { no strict 'refs'; *$sub_name = $sub_coderef; }
}

# This will run every action defined before
sub run { 
    my ($class, @suites) = @_;

    if (@suites > 0) {
        foreach my $a (@$actions) {
            $a->{code}->() if grep /$a->{name}/, @suites;
        }
    }
    else {
        $_->{code}->() for @$actions;
    }
}

1;

__END__

=pod

=head1 NAME

Test::WWW::Mechanize::Runner - test-suites maker for "WWW::Mechanize"-compatible agents.

=head1 DESCRIPTION

This module is designed to help you write functional test-suites for
web-applications without getting stuck with a specific WWW::Mechanize agent.

You write the scenario in your module (that inherits from the runner) and
define suites.

Then, you can easily write your test script with 3 lines.

=head1 EXAMPLE

First, write a scenario with the runner :

    package TestGoogle;
    use Test::Simple;
    use Test::WWW::Mechanize::Runner;
    use base 'Test::WWW::Mechanize::Runner'; # this may become automatic in
                                             # future versions
    
    suite google_homepage => sub {
        # you receive the agent defined for the session 
        my ($agent) = @_;

        ok( $agent->get('http://www.google.com'), 
            'GET http://www.google.com' );
        ok($agent->form_number(1), 'select the form' );
        # ... 
    };

    1;

Then you can write your test script for running the suite with the agent you
like:

    test-google-mozilla.t:

    use TestGoogle;
    TestGoogle->init('mozilla');
    TestGoogle->run(@ARGV);


The test suite is then run with a Mozilla::Mechanize agent, if possible.

You can also name the test suites you want to run if you want to run only a
specific set of suites, instead of all of them: 

    $ perl test-google-mozilla.t                 # will run all the test suites defined
    $ perl test-google-mozilla.t google_homepage # will only run "google_homepage"

=head1 SUPPORTED AGENTS

In this version the following agents are supported :

=over 4

=item B<default> : L<WWW::Mechanize>

=item B<mozilla> : L<Mozilla::Mechanize>

=item B<msie> : L<Win32::IE::Mechanize>

=item B<mozilla-gui> : L<Mozilla::Mechanize::GUITester>

=back

=head1 AUTHOR

This module was written by Alexis Sukrieh E<lt>sukria+perl@sukria.netE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
