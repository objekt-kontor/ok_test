package Ok::SampleTest;

use Ok::Test 'run_tests';

use Test::Assert ':assert';

sub new {
  my $class = shift;
  
  print "\nnew called\n";
  return bless {}, $class; 
}

sub set_up {
  print "\nset_up called\n";
}

sub tear_down{
  print "\ntear_down called\n";
}

sub something : Test {
  print "\ntest 'something' called\n";
  assert_true(0, "test 0 is true");
}

run_tests();

my $tests = Ok::Test::get_tests();

print $tests->{'Ok::SampleTest::something'}->{result};