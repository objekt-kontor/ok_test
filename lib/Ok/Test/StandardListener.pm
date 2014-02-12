package Ok::Test::StandardListener;

use strict;
use warnings;

use base qw(Ok::Test::Listener);

sub new { bless {}, shift }

sub on_before {}
 
sub on_pass {my $s = shift;  print STDOUT  "." }

sub on_fail {my $s = shift; print STDOUT "F" }

sub on_error {my $s = shift; print STDOUT "E" }

sub on_after { 
  my ($self, $test_list) = @_;
  
  my @passes  = grep { $_->result == Ok::Test::Result->PASS } @$test_list;
  my @fails   = grep { $_->result == Ok::Test::Result->FAIL } @$test_list;
  my @errors  = grep { $_->result == Ok::Test::Result->ERROR } @$test_list;
 
  my ($test_count, $pass_count, $fail_count, $error_count) = (scalar(@$test_list), scalar(@passes), scalar(@fails), scalar(@errors));
  
  print STDOUT "\nPassed $pass_count of $test_count tests\n";
  print STDOUT "\nThere were $fail_count failures.\n" if $fail_count > 1;
  print STDOUT "\nThere was 1 failure.\n" if $fail_count == 1;
  for(my $i = 0; $i < $fail_count; $i++) {
    my $e = $fails[$i]->error;
    
    print STDOUT ($i+1) . ") " . $fails[$i]->cannonical_method_name . "\n";
    print STDOUT "\t'" . ($e->message or $e->reason) . "' at " . $e->file . " line " . $e->line . ".";
  }
  print STDOUT "\n\nThere were $error_count errors.\n" if $error_count > 1;
  print STDOUT "There was 1 error.\n" if $error_count == 1; 
  for(my $i = 0; $i < $error_count; $i++) {
    my $msg = $errors[$i]->error->origin_exception . "";
    $msg =~ s/(\S)\s*$/$1.\n/ unless $msg =~ /\.$/;
    my $str =  ($i+1) . ") " . $errors[$i]->cannonical_method_name . " (" . $errors[$i]->error->type->name . " error)\n\t$msg\n";
   print STDOUT $str;
  }
  
} 
1