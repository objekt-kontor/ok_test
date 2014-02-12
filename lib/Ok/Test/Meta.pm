package Ok::Test::Meta;

use strict;
use warnings;


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
sub error { shift->{error} }
sub arguments { shift->{arguments} }

sub set_result {
  my ($self, $result) = @_;
  
  $self->{result} = $result;
  $self->{has_run} = 1;  
}

sub set_error {
  my ($self, $error) = @_;
  
  $self->{error} = $error;
}
1