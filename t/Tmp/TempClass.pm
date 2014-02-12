package Tmp::TempClass;

use Ok::Test;
use Test::Assert ':assert';

sub something_to_test : Test {
  assert_true(0, "hhmmm");
}

1