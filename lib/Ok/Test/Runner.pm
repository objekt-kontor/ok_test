package Ok::Test::Runner;

use strict;
use warnings;

=head1 NAME

Ok::Test::Runner - Simple XUnit framework using annotations!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use sigtrap;

use Ok::Test;
use Ok::Test::Result;
use Ok::Test::Error;
use Ok::Test::ErrorType;
use Ok::Test::StandardListener;

sub new {
  my ($class, $args) = @_;
  
  my $self = bless {listeners => []}, shift;
  
  my $listeners = $args->{listeners};
  if($listeners) {
    $self->_add_listener($_) for (@$listeners);
  } 
  
  $self->_add_listener($args->{listener});    
  
  return $self;
}


sub _add_listener {
  my ($self, $listener) = @_;
  
  return unless $listener;
  
  push(@{$self->{listeners}}, $listener);
}

sub _listeners { @{shift->{listeners}} } 

sub _run_test {
  my ($self, $test_data) = @_;
  
  return if $test_data->has_run;
  for my $l ($self->_listeners) {
    $l->on_before($test_data) if $l->can('on_before');
  } 

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
  $test_data->set_error(Ok::Test::Error->new($error, Ok::Test::ErrorType->CONSTRUCTOR));
  $test_data->set_result(Ok::Test::Result->ERROR);

  for my $l ($self->_listeners) {
    $l->on_error($test_data) if $l->can('on_error');
  }
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
  
  $test_data->set_error(Ok::Test::Error->new($error, Ok::Test::ErrorType->SET_UP));
  $test_data->set_result(Ok::Test::Result->ERROR);
  
  for my $l ($self->_listeners) {
    $l->on_error($test_data) if $l->can('on_error');
  }
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
  
  $test_data->set_result(Ok::Test::Result->PASS);
  for my $l ($self->_listeners) {
    $l->on_pass($test_data) if $l->can('on_pass');
  }
}

sub _handle_fail {
  my ($self, $test_data, $exception) = @_;
  
  $test_data->set_error($exception);
  $test_data->set_result(Ok::Test::Result->FAIL);
  
  for my $l ($self->_listeners) {
    $l->on_fail($test_data) if $l->can('on_fail');
  }
}

sub _handle_execution_error {
  my ($self, $test_data, $error) = @_;
  
  $test_data->set_error(Ok::Test::Error->new($error, Ok::Test::ErrorType->EXECUTION));
  $test_data->set_result(Ok::Test::Result->ERROR);
  
  for my $l ($self->_listeners) {
    $l->on_error($test_data) if $l->can('on_error');
  }
}

sub _do_tear_down {
  my ($self, $test_obj, $test_data) = @_;
  
  return unless $test_data->has_tear_down;
  eval { $test_obj->tear_down }
}

sub run {
  my $self = shift;
  sigtrap->import( qw/die normal-signals/ );
  sigtrap->import( qw/die error-signals/ );
    
  my @tests = $self->_get_runnable_tests();
  $self->_run_test($_) for (@tests);
  
  for my $l ($self->_listeners) {
    $l->on_after([@tests]) if $l->can('on_after');
  }
}

sub _get_runnable_tests {
  my $self = shift;
  
  my %test_meta = Ok::Test::get_loaded_tests();
  my @return_list = ();
  for my $test_data (values(%test_meta)) {
    push(@return_list, $test_data) unless $test_data->has_run;
  }
  return @return_list;
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
