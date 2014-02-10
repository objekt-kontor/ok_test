package Ok::Test;

use strict;
use warnings;

=head1 NAME

Ok::Test - Simple XUnit framework using annotations!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Attribute::Handlers;

use Exporter qw(import);

our @EXPORT_OK = qw(run_tests);

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

=head 2 Annotation Test
  
  a function that will be run in the test runner
  
=cut
my %TESTS     = ();
my @PASSES    = ();
my @FAILURES  = ();
my @ERRORS    = ();

sub UNIVERSAL::Test : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

  my $method = *{$symbol}{NAME};
  my $full_name = $package . "::" . $method;
    
  $TESTS{$full_name} = {
    has_new       => $package->can('new') ? 1 : 0,
    has_set_up    => $package->can('set_up') ? 1 : 0,
    has_tear_down => $package->can('set_up') ? 1 : 0,
    "package"     => $package, 
    method        => $method,
    filename      => $filename
  };
            
}


sub _get_object {
  my $method_path = shift;
  
  return unless exists $TESTS{$method_path};
  
  my $package = $TESTS{$method_path}->{'package'};
  return $package->new if $TESTS{$method_path}->{has_new};
  
  return bless {}, $package;
}

sub run_tests {
  for my $method_path (keys(%TESTS)) {
    my $obj;
    my $error;
    my $package = $TESTS{$method_path}->{"package"}; 
    my $method = $TESTS{$method_path}->{method};
    eval{ $obj = _get_object($method_path); };
    $error = $@;
    if($error) {
      $TESTS{$method_path}->{result} = "Error in constructing object: $error";
      next;
    }
    elsif(!$obj){
      $TESTS{$method_path}->{result} = "Error in constructing object.";
    }
    if(!$error) {
      eval { $obj->set_up() if $TESTS{$method_path}->{has_set_up}; };
      $error = $@;
      if($error) {
        $TESTS{$method_path}->{result} = "Error in setup: $error";
      }
      if(!$error) {
        eval { $obj->$method(); };
        $error = $@;
        if($error) {
          if( $error->isa('Exception::Assertion') ){
            my $details = $error->caller_stack;
            my $location = ();
            for(my $x = 0; $x < scalar(@$details); $x++) {
              $location = $details->[$x] if $details->[$x]->[0] eq $package;
            }
            my $message = join(" ", "'" . ($error->message ? $error->message : $error->reason) . "' at line: " . $location->[2], "in package: " . $package. "::" . $method . "()", "file: " . $location->[1] . "");
            $TESTS{$method_path}->{result} = "Failure: " .  $message;
          }
          else {
            $TESTS{$method_path}->{result} = "Error in test: " . $error;
          }
        }
      }
    }
    eval { $obj->tear_down } if $TESTS{$method_path}->{has_tear_down};
  }
}

sub get_tests {
  my  %tests = %TESTS;
  return {%tests};
}

=head1 AUTHOR

Craig Buchanan, C<< <ok_test at objekt-kontor.de> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ok::Test


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ok-Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ok-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ok-Test>

=item * Search CPAN

L<http://search.cpan.org/dist/Ok-Test/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Craig Buchanan.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Ok::Test
