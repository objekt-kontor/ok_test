use 5.006;
use strict;
use warnings FATAL => 'all';
#use Test::More;
#
#plan tests => 3;
use FindBin;
use lib $FindBin::Bin;
use lib "$FindBin::Bin/../lib";
#use Devel::Cover;
use Ok::Test::Runner;
#use Ok::SampleTest;
require 'Tmp/TempClass.pm';

#my %tests = Ok::Test::get_loaded_tests();
#my $t = $tests{'Ok::SampleTest::error'};
#print $t->package_name . ":\n";
#print "\t" . $t->arguments->[0]->{method} . "\n";
#print "\t\t" . $t->method . "\n";

my $runner = new Ok::Test::Runner({listener => Ok::Test::StandardListener->new, filter => TmpFilter->new});

$runner->run;

package TmpFilter;

sub new { bless {}, __PACKAGE__ }
sub should_run {
  my ($self, $test_meta) = @_;
  
  return 1;
  return $test_meta->filename =~ /t\/Ok\//;
  return 0 unless $test_meta->arguments;
  return 1 if $test_meta->arguments->[0] eq 'Unit';
}

package TmpListener;
  
sub new { bless {}, __PACKAGE__ }
sub on_before {
  my ($self, $test) = @_;
  
  print $test->cannonical_method_name . " ";
}

sub on_pass {
  print "yay\n";
}

sub on_fail {
  print "boo\n";
}

sub on_error {
  print "bummer\n";
}

sub on_after {
  my ($self, $tests) = @_;
  
  print "\n " . scalar(@$tests) . " tests run\n";
}