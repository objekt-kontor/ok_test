package Ok::Test::ErrorType;

use strict;
use warnings;

my $TYPES = {
  constructor => bless ({name => 'constructor'}, __PACKAGE__),
  set_up      => bless ({name => 'set_up'}, __PACKAGE__),
  execution   => bless ({name => 'execution'}, __PACKAGE__),
};

sub CONSTRUCTOR { $TYPES->{constructor} }

sub SET_UP { $TYPES->{set_up}; }

sub EXECUTION { $TYPES->{execution}; }

sub name { shift->{name} }



1;