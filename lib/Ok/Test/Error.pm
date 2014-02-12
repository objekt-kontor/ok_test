package Ok::Test::Error;

use strict;
use warnings;

sub new { 
  my ($class, $origin_exception, $type) = @_;
  
  bless { origin => $origin_exception, type => $type }, $class;
}

sub origin_exception { shift->{origin} }

sub type { shift->{type} }


1;