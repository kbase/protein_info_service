#!/kb/runtime/bin/perl
use strict;
no strict "refs";
use warnings;
use Test::More;

my @tests = ();
my $testCount = 0;
my $maxTestNum = 4;  # increment this each time you add a new test sub.

# keep adding tests to this list
unless (@ARGV) {
	for (my $i=1; $i <= $maxTestNum; $i++) {
		push @tests, $i;
	}
}

else {
	# need better funtionality here to accept things in the ARGV
	# like (12..17, 21, 27..30, 34)
	@tests = @ARGV;
}

# do anything here that is a pre-requisiste
my $client;

setup();

foreach my $num (@tests) {
       my $test = "test" . $num;
	&$test();
       $testCount++;
}

done_testing($testCount);
teardown();

# write your tests as subroutnes, add the sub name to @tests
sub test1 {
	require_ok("Bio::KBase::ProteinInfoService::Client");
}

sub test2 {
	$client = new_ok("Bio::KBase::ProteinInfoService::Client", ["http://localhost:7057"]);
}

sub test3 {
	my $fids = $client->fids_to_operons([]);
       ok(%$fids == 0,  (caller(0))[3] );
}
sub test4 {
	my $fids = $client->fids_to_operons([ "kb|g.20029.peg.3202" ]);
       ok(@{$fids->{'kb|g.20029.peg.3202'}} > 0,  (caller(0))[3] );
}


# needed to set up the tests, should be called before any tests are run
sub setup {

}

# this should be called after all tests are done to clean up the filesystem, etc.
sub teardown {
}


