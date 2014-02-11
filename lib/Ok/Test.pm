package Ok::Test;

use strict;
use warnings;

=head1 NAME

Ok::Test - Simple XUnit framework using annotations!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Ok::Test::Runner;
use sigtrap;

=head1 SYNOPSIS

Contains the Annotation handler and static functions for running tests.

Perhaps a little code snippet.

    use Ok::Test;

    use SomeClass::Containing::Annotations;
    
    run_tests();
    
    or run_test({
      
      reporter => $customReporter,
      filter   => [list_of_full_method_names or file_names]
    } )
    
=head2 Tests

When writing a test class the requirements are this file. Recommended is the Test::Assert library for making testing easier.
Ok::Test will run each method that is labeled with the : Test annotation as a separate test.
It will check to see if the containing class contains a new method and will attempt to instanciate the class using this method.
If no new method exist i.e. Class->can('new') is false, then the class will simply be a blessed hash.

Before if a set_up method exists it will be called before the test and consequently a tear_down method will be called after, if it exists.


=head1 EXPORT

=over 2

  run_tests
  get_tests

=back

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub run_tests {
  
  sigtrap->import( qw/die normal-signals/ );
  sigtrap->import( qw/die error-signals/ );
  
  my $runner = Ok::Test::Runner->new();
  $runner->run();
}

1; # End of Ok::Test
