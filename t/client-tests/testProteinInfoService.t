#!/usr/bin/perl

###############################################################################
# Client tests for the Protein Information Service
#
# Bill Riehl
# wjriehl@lbl.gov
# November 28, 2012
# November Build Meeting @ Argonne
# updated 12/6/2012 landml
# more updates 12 dec 2012 kkeller
###############################################################################

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use Getopt::Long;

use lib "lib";
use lib "t/client-tests";

my $num_tests = 0;
my $debug=0;
my $localServer=0;
#my $uri='http://140.221.92.231/services/protein_info_service';
my $uri='http://kbase.us/services/protein_info_service';
my $serviceName='ProteinInfoService';

my $getoptResult=GetOptions(
        'debug' =>      \$debug,
        'localServer'   =>      \$localServer,
	'uri=s'		=>	\$uri,
        'serviceName=s' =>      \$serviceName,
);



##########
# Make sure we locally load up the client library and JSON RPC
use_ok("Bio::KBase::ProteinInfoService::Client");
use_ok("JSON::RPC::Client");
$num_tests += 2;

##########
# Make sure we can instantiate a client

use Server;
my ($url,$pid);
# would be good to extract the port from a config file or env variable
$url=$uri unless ($localServer);
# Start a server on localhost if desired
($pid, $url) = Server::start($serviceName) if ($localServer);
print "Testing service $serviceName on $url\n";

##########
my $client = new_ok("Bio::KBase::ProteinInfoService::Client",[$url] );
$num_tests++;

# Make sure the client is of the right class
isa_ok($client, "Bio::KBase::ProteinInfoService::Client", "Is it the right class?");
$num_tests++;

#my @good_fids = qw(kb|g.21765.CDS.87 kb|g.21765.CDS.3228 kb|g.20029.peg.3202 kb|g.20029.peg.2255);
my @good_fids = qw(
kb|g.1870.peg.3069
kb|g.1084.peg.101
kb|g.357.peg.3639
);
# fids_to_orthologs is horribly slow, so test only one fid
my @good_ortholog_fids=qw(
kb|g.1084.peg.101
);

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
                happy => \@good_ortholog_fids,
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
note("test $num_tests and method $method_calls\n");
		eval { $result = $client->$call($method_calls->{$call}->{bad}); }
	}
	if ($@) { print "ERROR = $@\n"; }
	ok($result, "Got a response from \"$call\" with bad input");
	$num_tests++;
}

Server::stop($pid) if ($pid);
done_testing($num_tests);

