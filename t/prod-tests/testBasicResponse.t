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
my $host=getHost(); my $port=getPort();  my $url=getURL();
#print "-> attempting to connect to:'".$host.":".$port."'\n";
#my $client = Bio::KBase::ProteinInfoService::Client->new($host.":".$port);
print "-> attempting to connect to:'".$url."'\n";
my $client = Bio::KBase::ProteinInfoService::Client->new($url);

##########
# Make sure the client is of the right class
isa_ok($client, "Bio::KBase::ProteinInfoService::Client", "Is it the right class?");
$num_tests++;

my @method_calls = qw (fids_to_operons fids_to_domains domains_to_fids fids_to_ipr fids_to_orthologs fids_to_ec fids_to_go );
my @good_fids = ('kb|g.21765.CDS.87', 'kb|g.21765.CDS.3228', 'kb|g.20029.peg.3202', 'kb|g.20029.peg.2255');

#  Test 3 - Can the object do all of the methods
can_ok($client, @method_calls);    

note("Test the happy cases for gene calling methods");
my $results;

foreach my $method (@method_calls) {

        eval {$results = $client->$method(\@good_fids); };
        ok(!$@, "Test $method $@");
	$num_tests++;
}

done_testing($num_tests);

exit;

