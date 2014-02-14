use 5.006;
use strict;
use warnings FATAL => 'all';
#use Test::More;
#
#plan tests => 3;
use Getopt::Long;
use FindBin;
use lib $FindBin::Bin;
$ENV{AZ24Home} = "$FindBin::Bin/../../sources";
my $AZ24Home = $ENV{AZ24Home}; 
print "$AZ24Home \n"; 
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../sources/bll/site_perl";
use lib "$FindBin::Bin/../../sources/test/unit/site_perl";
use lib "$FindBin::Bin/../../sources/test/site_perl";
use lib "$FindBin::Bin/../../az24_local_env/site_perl";

#use Devel::Cover;
use Ok::Test::Runner;
my $run_file            = '';
my $run_test            = '';
GetOptions(
  "f=s"    => \$run_file,
  "t=s"    => \$run_test
);

#print "\nShould only run $run_file\n";
#print "\nShould only run $run_test\n";

use Ok::Test;
use Ok::SampleTest;
#use AZ24::AnredeTest;
#require $run_file if( $run_file && -f $run_file);

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