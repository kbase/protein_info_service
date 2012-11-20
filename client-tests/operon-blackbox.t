#!/usr/bin/perl -w
# Some tests on the OperonService client
# Bill Riehl
# wjriehl@lbl.gov
# Lawrence Berkeley Natural Lab
# 11/1/2012

use strict;
use Test::More 'no_plan';
use Test::Deep;
use Data::Dumper;

my $host_addr = "http://localhost:7057";
# only command to test = fids_to_operons

# Test 1: invoke the module
require_ok("Bio::KBase::ProteinInfoService::Client");

# Test 2: create a new service
my $service;
$service = new_ok("Bio::KBase::ProteinInfoService::Client", [$host_addr]);

# Test 3: did we get a valid service class?
ok(defined $service, "Did a service object get defined?");

# Test 4: is it the right class?
isa_ok($service, "Bio::KBase::ProteinInfoService::Client", "Is it the right class?");

# Test 5: can it invoke the method we want?
ok($service->can("fids_to_operons"), "Can we invoke fids_to_operons?");

my $gold_fid = "kb|g.20029.peg.3202";
my $gold_results = {
                     'kb|g.20029.peg.3202' => [ 'kb|g.20029.peg.3101',
                                                'kb|g.20029.peg.3013',
                                                'kb|g.20029.peg.3242',
                                                'kb|g.20029.peg.2956',
                                                'kb|g.20029.peg.3202',
                                                'kb|g.20029.peg.3005',
                                                'kb|g.20029.peg.3121',
                                                'kb|g.20029.peg.3287',
                                                'kb|g.20029.peg.3219',
                                                'kb|g.20029.peg.2895',
                                                'kb|g.20029.peg.2991' ]
                   };
my $result = $service->fids_to_operons([$gold_fid]);

# Test 6: Can we get results from valid input?
ok($result, "Do we get results from using valid data?");

# Test 7: Do those results match our gold standard?
ok($result->{$gold_fid}, "Do the results include our fid?");

# Test 8: Do they REALLY match the gold standard?
cmp_set($result->{$gold_fid}, $gold_results->{$gold_fid}, "Do the operon sets match?");

# Test 9: invoke the service with no data
$result = $service->fids_to_operons([]);
ok(%$result == 0, "Empty data returns an empty hash");

# Test 10: invoke the service with bad data
$result = $service->fids_to_operons(['bad data!']);
ok(%$result == 0, "Bad data retuns an empty hash");

# Test 11: invoke with good data, negative result (i.e. gene that's not in an operon)
my $neg_fid = "kb|g.20029.crispr.0";
$result = $service->fids_to_operons([$neg_fid]);
is_deeply($result, { $neg_fid => [ $neg_fid ] }, "Does a feature not in an operon only return itself in an operon?");
