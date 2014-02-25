use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ok::Test' ) || print "Bail out!\n";
}

diag( "Testing Ok::Test $Ok::Test::VERSION, Perl $], $^X" );
