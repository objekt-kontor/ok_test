package Ok::Test::Result;

use strict;
use warnings;

use Scalar::Util qw(refaddr);

my $RESULTS = {
  PASS  => bless ({name => 'PASS'}, __PACKAGE__),
  FAIL  => bless ({name => 'FAIL'}, __PACKAGE__),
  ERROR => bless ({name => 'ERROR'}, __PACKAGE__)
};

sub PASS {$RESULTS->{PASS}}
sub FAIL {$RESULTS->{FAIL}}
sub ERROR {$RESULTS->{ERROR}}

sub name { shift->{name} }

sub cmp {
  my ($self, $other) = @_;
  
  return 0 unless defined $other;
  return 0 unless ref($other);
  return refaddr($self) == refaddr($other); 
}
use overload 
  '==' => \&cmp,
  'eq' => \&cmp; 
  
1;