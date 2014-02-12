package Ok::SampleTest;

use Ok::Test;

use Test::Assert ':assert';

sub new {
  my $class = shift;
  
  return bless {}, $class; 
}

sub set_up {
}

sub tear_down{
}

sub pass : Test {
  assert_true(1, "a message");
}

sub error : Test {
  die "random error";
}

sub failure : Test {
  assert_false(1, "another message");
}

sub perl_sigterm : Test {
  `killall perl;`;
}

package HasConstructError;

sub new {
  die 'Arrrgghhh';
}

sub dies_on_construction : Test{}

package ReturnsNothingFromConstructor;

sub new {
  return;
}

sub returns_nothing_from_new : Test {}

package DiesInSetup;

sub set_up {
  die "set_up to die";
}

sub dies_in_set_up : Test {}


1