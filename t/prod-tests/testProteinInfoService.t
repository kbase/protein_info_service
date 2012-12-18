#!/usr/bin/perl

###############################################################################
# Client tests for the Protein Information Service
#
# Bill Riehl
# wjriehl@lbl.gov
# November 28, 2012
# November Build Meeting @ Argonne
# updated 12/6/2012 landml
###############################################################################

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use lib "lib";
use lib "t/prod-tests";
use ProteinTestConfig qw(getHost getPort getURL);

my $num_tests = 0;

##########
# Make sure we locally load up the client library and JSON RPC
use_ok("Bio::KBase::ProteinInfoService::Client");
use_ok("JSON::RPC::Client");

$num_tests += 2;

##########
# MAKE A CONNECTION (DETERMINE THE URL TO USE BASED ON THE CONFIG MODULE)
# Make sure we can instantiate a client
my $host=getHost(); my $port=getPort();  my $url = getURL();
#print "-> attempting to connect to:'".$host.":".$port."'\n";
#my $client = new_ok("Bio::KBase::ProteinInfoService::Client",[$host.":".$port] );
print "-> attempting to connect to:'".$url."'\n";
my $client = new_ok("Bio::KBase::ProteinInfoService::Client",[$url] );
$num_tests++;

##########
# Make sure the client is of the right class
isa_ok($client, "Bio::KBase::ProteinInfoService::Client", "Is it the right class?");
$num_tests++;

my @good_fids = qw(kb|g.21765.CDS.87 kb|g.21765.CDS.3228 kb|g.20029.peg.3202 kb|g.20029.peg.2255);
my @empty_fids = qw();
my @bad_fids = qw(bad_fid this_is_bad_too);

my @good_domains = qw(PF00308 PF08399);
my @empty_domains = qw();
my @bad_domains = qw(bad_domain another_bad_domain);

my $method_calls = {
	fids_to_operons => {
		happy => \@good_fids,
		empty => \@empty_fids,
		bad => \@bad_fids
	},
	fids_to_domains => {
                happy => \@good_fids,
                empty => \@empty_fids,
                bad => \@bad_fids
        },
	domains_to_fids => {
                happy => \@good_domains,
                empty => \@empty_domains,
                bad => \@bad_domains
        },
	fids_to_ipr => {
                happy => \@good_fids,
                empty => \@empty_fids,
                bad => \@bad_fids
        },
	fids_to_orthologs => {
                happy => \@good_fids,
                empty => \@empty_fids,
                bad => \@bad_fids
        },
	fids_to_ec => {
                happy => \@good_fids,
                empty => \@empty_fids,
                bad => \@bad_fids
        },
	fids_to_go => {
                happy => \@good_fids,
                empty => \@empty_fids,
                bad => \@bad_fids
        },
};

foreach my $call (keys %{ $method_calls }) {
	my $result;
	print "\nTesting function \"$call\"\n";
	{
		no strict "refs";
		eval { $result = $client->$call($method_calls->{$call}->{happy}); };
	}
	
#	if ($@) { print "ERROR = $@\n"; }
	
	## 1. Test if we got a result of any kind from the method call.
	ok($result, "Got a response from \"$call\" with happy data");
	$num_tests++;	
	# warn Dumper($result);
	# this works because we're only passing an array ref for each method,
	# so don't copy this bit to other modules...

	## 2. Test that we got the number of elements in the result that we expect.
	# (this works because we're only passing an array ref for each method,
        # so don't copy this bit to other modules...)
	is(scalar(keys %{ $result }), scalar(@{ $method_calls->{$call}->{happy} }), "\"$call\" returned the same number of elements that was passed");
	$num_tests++;
	
	## 3. Test that the elements returned are the correct values.
	# (we don't really care about the actual values of the calls)
	my @keys = keys %{ $result };
	cmp_set(\@keys, $method_calls->{$call}->{happy}, "\"$call\" returned the correct set of elements");
	$num_tests++;

	## 4. Test that the actual values are unique in the list.
	# Again, we don't care what they are, only that there's one of each.
	my $num_uniq_results = 0;
	foreach my $key (keys %{ $result }) {
		# a little voodoo to get a unique version of an array.
		# it maps all elements in the array into a hash where the values are just 1,
		# then gets the number of keys.
		# Perl - the write-only language, at work.
		my $count = scalar(keys %{{ map { $_ => 1 } @{$result->{$key}} }});
		# print $count . " " . scalar(@{ $result->{$key} }) . "\n";
		if ($count == scalar(@{ $result->{$key} })) {
			$num_uniq_results++;
		}
	}
	ok($num_uniq_results == scalar(keys(%{ $result })), "\"$call\" returned unique sets of results");
	$num_tests++;

	## 5. Test with empty (but correctly formatted) values.
	{
		no strict "refs";
		eval { $result = $client->$call($method_calls->{$call}->{empty}); }
	}
	if ($@) { print "ERROR = $@\n"; }
	ok($result, "Got a response from \"$call\" with empty input");
	$num_tests++;

	## 6. Test with bad (but correctly formatted) data.
	{
		no strict "refs";
		eval { $result = $client->$call($method_calls->{$call}->{bad}); }
	}
	if ($@) { print "ERROR = $@\n"; }
	ok($result, "Got a response from \"$call\" with bad input");
	$num_tests++;
}

done_testing($num_tests);

