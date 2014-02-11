package Ok::Test::Runner;

use strict;
use warnings;

=head1 NAME

Ok::Test::Runner - Simple XUnit framework using annotations!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Attribute::Handlers;

my %TESTS     = ();

sub UNIVERSAL::Test : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

  my $method = *{$symbol}{NAME};
  my $full_name = $package . "::" . $method;
    
  $TESTS{$full_name} = TestMetaData->new({
    has_new                => $package->can('new') ? 1 : 0,
    has_set_up             => $package->can('set_up') ? 1 : 0,
    has_tear_down          => $package->can('set_up') ? 1 : 0,
    package_name           => $package, 
    method                 => $method,
    cannonical_method_name => $full_name,
    filename               => $filename
  });
            
}

sub new {
  my ($class, $args) = @_;
  
  my $self = bless {}, shift;
  
  if(exists($args->{listener})) {
    my $l = $args->{listener};
    $self->_add_before_listener($l);
    $self->_add_pass_listener($l);
    $self->_add_fail_listener($l);
    $self->_add_error_listener($l);
    $self->_add_tests_run_listener($l);
  }

  $self->add_before_listener($args->{before_listener}) if exists($args->{before_listener});
  $self->add_pass_listener($args->{pass_listener}) if exists($args->{pass_listener});
  $self->add_fail_listener($args->{fail_listener}) if exists($args->{fail_listener});
  $self->add_error_listener($args->{error_listener}) if exists($args->{error_listener});
  $self->add_error_listener($args->{tests_run_listener}) if exists($args->{tests_run_listener});
  
  $self->set_default_listener if $self->_no_listeners_set;
  return $self;
}

sub add_before_listener { shift->__add_listener(@_, 'before') }
sub add_pass_listener { shift->__add_listener(@_, 'pass') }
sub add_fail_listener { shift->__add_listener(@_, 'fail') }
sub add_error_listener { shift->__add_listener(@_, 'error') }
sub add_tests_run_listener { shift->__add_listener(@_, 'tests_run') }

sub __add_listener {
  my ($self, $listener, $type) = @_;
  
  my $prop = $type . "_listeners";
  my $meth = 'on_' . $type;

  $self->{$prop} = [] unless $self->{$prop};
  if($listener->can($meth)) {
    push(@{$self->{$prop}}, $listener);
  }
}

sub _listeners {
  my ($self, $type) = @_;
  
  my $prop = $type . "_listeners";
  $self->{$prop} = [] unless $self->{$prop};
  
  my @listeners = @{$self->{$prop}};
  return @listeners; 
}

sub _before_listeners { shift->_listeners('before') }
sub _pass_listeners { shift->_listeners('pass') }
sub _error_listeners { shift->_listeners('error') }
sub _fail_listeners { shift->_listeners('fail') }
sub _tests_run_listeners { shift->_listeners('tests_run') }

sub _no_listeners_set {
  my $self = shift;
  
  return !scalar($self->_before_listeners, $self->_pass_listeners, $self->_error_listeners, $self->_fail_listeners, $self->_tests_run_listeners);
}

sub set_default_listener {
  my $self = shift;
  
  my $l = Ok::Test::StandardListener->new;
  $self->add_before_listener($l);
  $self->add_pass_listener($l);
  $self->add_fail_listener($l);
  $self->add_error_listener($l);
  $self->add_tests_run_listener($l);
}

sub _run_test {
  my ($self, $test_data) = @_;
  
  return if $test_data->has_run;
  
  $_->on_before($test_data) for($self->_before_listeners);

  my $obj = $self->_construct_test_object($test_data);
  return unless $obj;
  
  if ($self->_do_set_up($obj, $test_data)) {
    $self->_execute_test($obj, $test_data);
  }
  $self->_do_tear_down($obj, $test_data);
}

sub _construct_test_object {
  my ($self, $test_data) = @_;
  
  my $package = $test_data->package_name;
  if( $test_data->has_new) { 
    my $obj = eval { $package->new };
    my $error = $@;
    return $obj if $obj;
    
    $self->_handle_constructor_error($test_data, $error) ;
    return;
  }
  return bless {}, $package;
}

sub _handle_constructor_error {
  my ($self, $test_data, $error) = @_;
  
  $error = "Nothing returned from constructor\n" unless $error;
  $test_data->set_result(Ok::Test::Error::SetUp->new($error));
  $_->on_error($test_data) for ($self->_error_listeners);
}

sub _do_set_up {
  my ($self, $test_obj, $test_data) = @_;
  
  return 1 unless $test_data->has_set_up;
  
  eval { $test_obj->set_up() };
  my $error = $@;
  
  return 1 unless $error;
  
  $self->_handle_set_up_error($test_data, $error);
}

sub _handle_set_up_error {
  my ($self, $test_data, $error) = @_;
  
  $test_data->set_result(Ok::Test::Error::SetUp->new($error));
  $_->on_error($test_data) for ($self->_error_listeners);
}

sub _execute_test {
  my ($self, $test_obj, $test_data) = @_;
  
  my $method = $test_data->method;
  eval { $test_obj->$method(); };
  my $error = $@;
  
  return $self->_handle_pass($test_data) unless $error;
  return $self->_handle_fail($test_data, $error) if ref($error) && $error->isa('Exception::Assertion');
  return $self->_handle_execution_error($test_data, $error);
    
}

sub _handle_pass {
  my ($self, $test_data) = @_;
  
  $test_data->set_result(Ok::Test::Pass->new);
  $_->on_pass($test_data) for ($self->_pass_listeners());
}

sub _handle_fail {
  my ($self, $test_data, $exception) = @_;
  
  $test_data->set_result(Ok::Test::Fail->new($exception));
  $_->on_fail($test_data) for ($self->_fail_listeners());
}

sub _handle_execution_error {
  my ($self, $test_data, $error) = @_;
  
  $test_data->set_result(Ok::Test::Error::Execution->new($error));
  $_->on_error($test_data) for ($self->_error_listeners());
}

sub _do_tear_down {
  my ($self, $test_obj, $test_data) = @_;
  
  return unless $test_data->has_tear_down;
  eval { $test_obj->tear_down }
}

sub run {
  my $self = shift;
    
  my @tests = $self->_get_runnable_tests();
  $self->_run_test($_) for (@tests);
  
  $_->on_tests_run([@tests]) for ($self->_tests_run_listeners);
}

sub _get_all_tests {
  my  %tests = %TESTS;
  return %tests;
}

sub _get_runnable_tests {
  my $self = shift;
  
  my %test_meta = _get_all_tests;
  my @return_list = ();
  for my $test_data (values(%test_meta)) {
    push(@return_list, $test_data) unless $test_data->has_run;
  }
  return @return_list;
}


package TestMetaData;
  
sub new {
  my ($class, $args) = @_;
  $args->{has_run} = 0;
  bless $args, shift;
}

sub has_new { shift->{has_new}; }
sub has_set_up { shift->{has_set_up} }
sub has_tear_down { shift->{has_tear_down} }
sub package_name { shift->{package_name} }
sub method { shift->{method} }
sub cannonical_method_name { shift->{cannonical_method_name} }
sub filename { shift->{filename} }
sub has_run { shift->{has_run} }
sub result { shift->{result} }

sub set_result {
  my ($self, $result) = @_;
  
  $self->{result} = $result;
  $self->{has_run} = 1;  
}

package Ok::Test::Error;

sub new { 
  my ($class, $origin_exception, $type) = @_;
  bless { origin => $origin_exception, type => $type }, $class;
}

sub origin_exception { shift->{origin} }
sub type { shift->{type} }

package Ok::Test::Error::Constructor;

use base 'Ok::Test::Error';

sub new { shift->SUPER::new(@_, 'Constuctor') } 

package Ok::Test::Error::SetUp;
use base 'Ok::Test::Error';

sub new { shift->SUPER::new(@_, 'SetUp') } 


package Ok::Test::Error::Execution;
use base 'Ok::Test::Error';

sub new { shift->SUPER::new(@_, 'Execution') } 

package Ok::Test::Fail;

sub new {
  my ($class, $exception) = @_;
  
  bless {exception => $exception}, $class; 
}

sub exception { shift->{exception} }

package Ok::Test::Pass;

sub new { bless {}, shift }

package Ok::Test::StandardListener;

sub new { bless {}, shift }

sub on_before {my $s = shift; print STDOUT shift->cannonical_method_name }
 
sub on_pass {my $s = shift;  print STDOUT  "." }

sub on_fail {my $s = shift; print STDOUT "F" }

sub on_error {my $s = shift; print STDOUT "E" }

sub on_tests_run { 
  my ($self, $test_list) = @_;
  
  my @passes  = grep { $_->result->isa('Ok::Test::Pass') } @$test_list;
  my @fails   = grep { $_->result->isa('Ok::Test::Fail') } @$test_list;
  my @errors  = grep { $_->result->isa('Ok::Test::Error') } @$test_list;
 
  my ($test_count, $pass_count, $fail_count, $error_count) = (scalar(@$test_list), scalar(@passes), scalar(@fails), scalar(@errors));
  
  print STDOUT "\nPassed $test_count of " . scalar(@$test_list) . " tests\n";
  print STDOUT "There were $fail_count failures.\n" if $fail_count > 1;
  print STDOUT "There was 1 failure.\n" if $fail_count == 1;
  for(my $i = 0; $i < $fail_count; $i++) {
    print STDOUT ($i+1) . ") " . $fails[$i]->cannonical_method_name . "\n";
    print STDOUT "\t'" . ($fails[$i]->result->exception->message or $fails[$i]->result->exception->reason) . "'";
  }
  print STDOUT "There were $error_count errors.\n" if $error_count > 1;
  for(my $i = 0; $i < $error_count; $i++) {
    print STDOUT ($i+1) . ") " . $errors[$i]->cannonical_method_name . "\n";
    print STDOUT "\t" . $errors[$i]->result->origin_exception . "\n";
  }
  print STDOUT "There was 1 error.\n" if $error_count == 0;
  
  
  
  
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
