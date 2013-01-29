#!/usr/bin/perl -w
package Bio::KBase::ProteinInfoService::Regulon;
require Exporter;

use strict;
use Bio::KBase::ProteinInfoService::GenomicsUtils;
use Bio::KBase::ProteinInfoService::Gene;
## Regulon Object
## Methods Declaration

sub new; # Regulon object is created by a given cluster ID 
sub loci; # return a list of Gene objects in the regulon
sub lociID; # return a list of Locus IDs in the regulon
sub clusterId; #return the cluster ID
sub links; # return a list of Regulon objects that are link to the query Regulon object
sub transFactors; # return a list of Gene objects that are putative TFs



## Methods

sub new{
    my %params = @_; #keys are: clusterId
    die "No clusterId declared in Bio::KBase::ProteinInfoService::Regulon::new()" unless defined($params{clusterId});
    my $self = {};
    bless $self;
    my $sql = qq{
	
	SELECT locusId
	FROM RegulonCluster
	WHERE clusterId=$params{clusterId}

    };

    my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);

    return undef if @$queryR == 0;

    
    $self->{clusterId_} = $params{clusterId};
    foreach (@$queryR){
	push @{$self->{lociID_}}, $_->[0];
	push @{$self->{loci_}}, Bio::KBase::ProteinInfoService::Gene::new(locusId=>$_->[0]);
    }
    return $self;
}

sub loci{
    my $self = shift;
    return @{$self->{loci_}};
}

sub lociID{
    my $self = shift;
    return @{$self->{lociID_}};

}

sub clusterId{
    my $self = shift;
    return $self->{clusterId_};
}

sub links{
    my $self = shift;
    my $clusterId = $self->clusterId();
    my %params = @_; # keys: linkType # values: linkType eq "m" or "g"
    die "No linkType provided in Bio::KBase::ProteinInfoService::Regulon::links()" unless defined($params{linkType});
    $params{linkType} = $params{linkType} eq 'm'?"MAcorr":"GNScore";
    unless (defined($self->{link_}{$params{linkType}})){
	my $sql = qq{
	    SELECT cluster2
	    FROM RegulonLinks
	    WHERE cluster1=$clusterId
	    AND link="$params{linkType}"
	};
	my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
	return if scalar(@$queryR) == 0;
	foreach (@$queryR){
	    push @{$self->{link_}{$params{linkType}}}, new(clusterId=>$_->[0]);
	}
    }
    return  @{$self->{link_}{$params{linkType}}};
}

sub transFactors{
    my $self = shift;
    my $loci = join ",", @{$self->{lociID_}};
    unless (defined($self->{tf_})) {
	my $goTerm = Bio::KBase::ProteinInfoService::GenomicsUtils::queryScalar('SELECT id FROM term where acc="GO:0003700"');
	my $sql = qq{
	    SELECT distinct(locusId) 
	    FROM Locus2Go 
	    WHERE goId=$goTerm
	    AND locusId in ($loci)
	};
			   
	my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
	return if scalar(@$queryR) == 0;
	foreach (@$queryR){
	    push @{$self->{tf_}}, Bio::KBase::ProteinInfoService::Gene::new(locusId=>$_->[0]);
	}
    }
    return @{$self->{tf_}};
}

1;
