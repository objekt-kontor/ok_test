package Ok::Test::StdOutReporter;

use strict;
use warnings;

use base qw(Ok::Test::Listener);

sub new { bless {
  tests   => [],
  passes  => [],
  fails   => [],
  errors  => [],
}, shift }

sub on_before {}
 
sub on_pass {my $s = shift;  print STDOUT  "." }

sub on_fail {my $s = shift; print STDOUT "F" }

sub on_error {my $s = shift; print STDOUT "E" }

sub on_after { 
  my ($self, $test_list) = @_;
  
  $self->_group_results($test_list);
 
  $self->display_summary;
} 

sub display_summary {
  my $self = shift;
  
  print STDOUT "\nPassed " . $self->pass_count . " of " . $self->test_count . " tests\n";
  
  $self->_display_failures;
  
  $self->_display_errors;
  
  $self->_display_error_failure_summary;
  
  
}

sub _display_failures {
  my $self = shift;
  
  my $fail_count = $self->fail_count;
  
  print STDOUT "\nThere were $fail_count failures.\n" if $fail_count > 1;
  print STDOUT "\nThere was 1 failure.\n" if $fail_count == 1;
  
  my $i = 1;
  for my $f (@{$self->fails}) {
    my $e = $f->error;
    
    print STDOUT "$i) " . $f->cannonical_method_name . "\n";
    print STDOUT "\t'" . ($e->message or $e->reason) . "' at " . $e->file . " line " . $e->line . ".\n";
    $i++;
  }
}

sub _display_errors {
  my $self = shift;
  
  my $error_count = $self->error_count;
  return unless $error_count; 
  print STDOUT "\nThere were $error_count errors.\n" if $error_count > 1;
  print STDOUT "\nThere was 1 error.\n" if $error_count == 1;
  
  my $i = 1; 
  for my $e (@{$self->errors}) {
  
    my $msg = $e->error->origin_exception . "";
    $msg =~ s/(\S)\s*$/$1.\n/ unless $msg =~ /\.$/;
  
    print STDOUT "$i) " . $e->cannonical_method_name . " (" . $e->error->type->name . " error)\n";
    print STDOUT "\t$msg\n";

    $i++;
  }
}

sub _display_error_failure_summary {
  my $self = shift;
  
  return print STDOUT "SUCCESS!\n" if $self->test_run_passed;
  return print STDOUT "No tests run!\n" unless $self->test_count;
  
  print STDOUT "\nFAILURE!\n";
  
  my ($f_cnt, $e_cnt) = ($self->fail_count, $self->error_count);
  
  print STDOUT "\nThere " . ($f_cnt == 1 ? "was 1 failure" : "were $f_cnt failures") . " and ";
  print STDOUT ($e_cnt == 1 ? "1 error" : "$e_cnt errors") . ".\n";
}

sub _group_results {
  my ($self, $test_list) = @_;
  
  $self->{tests}  = $test_list;
  
  $self->{passes} = [grep { $_->result == Ok::Test::Result->PASS } @$test_list];
  $self->{fails}  = [grep { $_->result == Ok::Test::Result->FAIL } @$test_list];
  $self->{errors} = [grep { $_->result == Ok::Test::Result->ERROR } @$test_list];
}

sub tests  { shift->{tests} }

sub test_count { scalar @{shift->tests} }

sub passes { shift->{passes} }

sub pass_count { scalar @{shift->{passes}} }

sub errors { shift->{errors} }

sub error_count { scalar @{shift->{errors}} }

sub fails  { shift->{fails} }

sub fail_count { scalar @{shift->{fails}} }

sub test_run_passed {
  my $self = shift;
   
  return 0 if $self->error_count;
  return 0 if $self->fail_count;
  return 0 unless $self->pass_count;

  return 1;
}
1