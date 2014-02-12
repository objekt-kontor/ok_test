use 5.006;
use strict;
use warnings FATAL => 'all';
#use Test::More;
#
#plan tests => 3;
use FindBin;
use lib $FindBin::Bin;

use Ok::Test::Runner;
use Ok::SampleTest;

my $runner = new Ok::Test::Runner({listener => Ok::Test::StandardListener->new});

$runner->run;


