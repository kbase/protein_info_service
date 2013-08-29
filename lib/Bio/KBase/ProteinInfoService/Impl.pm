package Bio::KBase::ProteinInfoService::Impl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

ProteinInfo

=head1 DESCRIPTION

Given a feature ID that is a protein, the protein info service
returns various annotations such as domain annotations, orthologs
in other genomes, and operons.

=cut

#BEGIN_HEADER

use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Config::Simple;

use Bio::KBase;
use Bio::KBase::MOTranslationService::Impl;
use DBKernel;

# This use statement drags in a whole boatload of MO stuff along with
# it - will need to be pruned down
# sychan 1/30/2013
use Bio::KBase::ProteinInfoService::Gene;

#use ContextAdapter;

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

	my $kb = Bio::KBase->new();
#	my $kbIdServer = $kb->id_server();
	my $kbCDM = $kb->central_store;
	# Load the translation service implementation directly to avoid timeouts and overhead from
        # rpc transport
	my $kbMOT = Bio::KBase::MOTranslationService::Impl->new();

        # Need to initialize the database handler for that Bio::KBase::ProteinInfoService::Gene depends on
        # the GenomicsUtils module caches the database handle internally

        my $configFile = $ENV{KB_DEPLOYMENT_CONFIG};
	# don't want this hardcoded; figure out what make puts out
            my $SERVICE = $ENV{SERVICE};

            my $config = Config::Simple->new();
            $config->read($configFile);
            my @paramList = qw(dbname sock user pass dbhost port dbms);
	    my %params;
            foreach my $param (@paramList)
            {
                my $value = $config->param("$SERVICE.$param");
                if ($value)
                {
                    $params{$param} = $value;
                }
            }

	# on devdb1.newyork
	my $dbms='mysql';
	my $dbName='genomics_dev';
	my $user='genomicsselect';
	my $pass='kusei*kulm';
	my $port=3306;
	my $dbhost='devdb1.newyork.kbase.us';
	my $sock='';
	
        my $dbKernel = DBKernel->new(
		$params{dbms}, $params{dbname},
		 $params{user}, $params{pass}, $params{port},
		 $params{dbhost}, $params{sock},
		);
        my $moDbh=$dbKernel->{_dbh};
        #my $dbKernel_dev = DBKernel->new($dbms_dev, $dbName_dev, $user_dev, $pass_dev, $port_dev, $dbhost_dev, $sock_dev);
        #my $moDbh_dev=$dbKernel_dev->{_dbh};
        #my $gene_dbh = Bio::KBase::ProteinInfoService::Browser::DB::dbConnect($dbhost_dev,$user_dev,$pass_dev,$dbName_dev);

#	$self->{kbIdServer}=$kbIdServer;
	$self->{kbCDM}=$kbCDM;
	$self->{kbMOT}=$kbMOT;
	$self->{moDbh}=$moDbh;
        #$self->{moDbh_dev} = $moDbh_dev;
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 fids_to_operons

  $return = $obj->fids_to_operons($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.operon
fid is a string
operon is a reference to a list where each element is a ProteinInfo.fid

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.operon
fid is a string
operon is a reference to a list where each element is a ProteinInfo.fid


=end text



=item Description

fids_to_operons takes as input a list of feature
ids and returns a mapping of each fid to the operon
in which it is found. The list of fids in the operon
is not necessarily in the order that the fids are found
on the genome.  (fids_to_operons is currently not properly
implemented.)

=back

=cut

sub fids_to_operons
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_operons:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_operons');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_operons

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbCDM=$self->{kbCDM};
		my $kbMOT=$self->{kbMOT};

		my $externalIds=$kbMOT->fids_to_moLocusIds($fids);

		my $operons={};
		foreach my $kbId (keys %$externalIds)
		{
			# to do: would like to reduce the number of locusIds being
			# passed to this query
			my $placeholders='?,' x (scalar @{$externalIds->{$kbId}});
			chop $placeholders;
			my $operonSql="SELECT o2.locusId
		       		FROM Locus2Operon o1, Locus2Operon o2
				WHERE o1.locusId IN ($placeholders)
				AND o1.tuId=o2.tuId
				ORDER BY o2.locusId";

			# this is currently the only ProteinInfo method
			# that needs to return genes from the same genome
			# so doing this as a one-off is not horrible
			# (it will be replaced by ER methods anyway once
			# operons are a data type in KBase land)

			my $operonLocusIdList=$moDbh->selectcol_arrayref($operonSql,{},@{$externalIds->{$kbId}}) || [];
			my $moOperonIds_to_kbaseIds=$kbMOT->moLocusIds_to_fids($operonLocusIdList);

			my $genomes=$kbCDM->fids_to_genomes([$kbId]);
			my $genome=$genomes->{$kbId};

			my $kbOperonIds;
			# craziness: try to limit operon to the original genome
			# potentially different operons are called in
			# different genomes
			foreach my $moOperonId (keys %$moOperonIds_to_kbaseIds)
			{
				next unless ($moOperonIds_to_kbaseIds->{$moOperonId} and scalar @{$moOperonIds_to_kbaseIds->{$moOperonId}});
				my $operonGenomes=$kbCDM->fids_to_genomes($moOperonIds_to_kbaseIds->{$moOperonId});
				foreach my $kbOperonId (keys %$operonGenomes)
				{
					my $operonGenome=$operonGenomes->{$kbOperonId};
					$kbOperonIds->{$kbOperonId}=1 if ($genome eq $operonGenome);
				}
			}

			my @kbOperonIds=keys %$kbOperonIds;
			$operons->{$kbId}=\@kbOperonIds || [$kbId];
		}
		$return=$operons|| {};
	}

    #END fids_to_operons
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_operons:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_operons');
    }
    return($return);
}




=head2 fids_to_domains

  $return = $obj->fids_to_domains($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.domains
fid is a string
domains is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.domains
fid is a string
domains is a reference to a list where each element is a string


=end text



=item Description

fids_to_domains takes as input a list of feature ids, and
returns a mapping of each fid to its domains. (This includes COG,
even though COG is not part of InterProScan.)

=back

=cut

sub fids_to_domains
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_domains:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_domains');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_domains

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			my $domainSql='SELECT locusId,domainId FROM Locus2Domain WHERE
				locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $domainSth=$moDbh->prepare($domainSql);
			$domainSth->execute($fids2externalIds->{$fid}[0]);

			my %domains;

			while (my $row=$domainSth->fetch)
			{
				$domains{$row->[1]} += 1;
			}

			my $cogSql='SELECT locusId,CONCAT("COG",cogInfoId) FROM COG WHERE
				locusId = ?';
		
			my $cogSth=$moDbh->prepare($cogSql);
			$cogSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$cogSth->fetch)
			{
				$domains{$row->[1]} += 1;
			}

			@{$return->{$fid}}=keys %domains;

		}
	}

    #END fids_to_domains
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_domains:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_domains');
    }
    return($return);
}




=head2 fids_to_domain_hits

  $return = $obj->fids_to_domain_hits($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.Hit
fid is a string
Hit is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.Hit
fid is a string
Hit is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float


=end text



=item Description

fids_to_domain_hits takes as input a list of feature ids, and
returns a mapping of each fid to a list of hits. (This includes COG,
even though COG is not part of InterProScan.)

=back

=cut

sub fids_to_domain_hits
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_domain_hits:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_domain_hits');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_domain_hits
        $return={};

        if (scalar @$fids)
        {
#               my $ctxA = ContextAdapter->new($ctx);
#               my $user_token = $ctxA->user_token();

                my $moDbh=$self->{moDbh};
                my $kbMOT=$self->{kbMOT};

                my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

                # this is not the best way, but should work
                foreach my $fid (keys %$fids2externalIds)
                {
                        my $domainSql='SELECT locusId,domainId,domainName,iprName,seqBegin,seqEnd,domainBegin,domainEnd,score,evalue,domainDb FROM Locus2Domain LEFT JOIN DomainInfo USING (domainId) WHERE
                                locusId = ?';
#                       my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#                       chop $placeholders;
#                       $sql.=$placeholders.')';

                        my $domainSth=$moDbh->prepare($domainSql);
                        $domainSth->execute($fids2externalIds->{$fid}[0]);

                        my $hits=[];

                        while (my $row=$domainSth->fetch)
                        {
                                # one of the DBI convenience methods
                                # would be more readable here
                                push @$hits, {
                                        id      =>      $row->[1],
                                        description     =>      $row->[2] . ' ' . $row->[3],
                                        queryBegin      =>      $row->[4],
                                        queryEnd        =>      $row->[5],
                                        subjectBegin    =>      $row->[6],
                                        subjectEnd      =>      $row->[7],
                                        score   =>      $row->[8],
                                        evalue  =>      $row->[9],
                                        subjectDb       =>      $row->[10],
                                };
                        }

                        my $cogSql='select c.locusId, CONCAT("COG",c.cogInfoId),geneName,description,qBegin,qEnd,sBegin,sEnd,score,evalue,"COG" from COG c join COGrpsblast rps ON (c.locusId=rps.locusId and c.version=rps.version and c.cogInfoId=rps.subject) JOIN COGInfo ci ON (c.cogInfoId=ci.cogInfoId) WHERE c.locusId=?';

                        my $cogSth=$moDbh->prepare($cogSql);
                        $cogSth->execute($fids2externalIds->{$fid}[0]);
                        while (my $row=$cogSth->fetch)
                        {
                                # one of the DBI convenience methods
                                # would be more readable here
                                push @$hits, {
                                        id      =>      $row->[1],
                                        description     =>      $row->[2] . ' ' . $row->[3],
                                        queryBegin      =>      $row->[4],
                                        queryEnd        =>      $row->[5],
                                        subjectBegin    =>      $row->[6],
                                        subjectEnd      =>      $row->[7],
                                        score   =>      $row->[8],
                                        evalue  =>      $row->[9],
                                        subjectDb       =>      $row->[10],
                                };
                        }

                        $return->{$fid}=$hits;

                }
        }
    #END fids_to_domain_hits
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_domain_hits:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_domain_hits');
    }
    return($return);
}




=head2 domains_to_fids

  $return = $obj->domains_to_fids($domain_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a reference to a list where each element is a ProteinInfo.fid
domains is a reference to a list where each element is a string
domain_id is a string
fid is a string

</pre>

=end html

=begin text

$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a reference to a list where each element is a ProteinInfo.fid
domains is a reference to a list where each element is a string
domain_id is a string
fid is a string


=end text



=item Description

domains_to_fids takes as input a list of domain_ids, and
returns a mapping of each domain_id to the fids which have that
domain. (This includes COG, even though COG is not part of
InterProScan.)

=back

=cut

sub domains_to_fids
{
    my $self = shift;
    my($domain_ids) = @_;

    my @_bad_arguments;
    (ref($domain_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"domain_ids\" (value was \"$domain_ids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to domains_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'domains_to_fids');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN domains_to_fids

	$return={};
	
	my $moDbh=$self->{moDbh};
	my $kbMOT=$self->{kbMOT};

	if (scalar @$domain_ids)
	{

		# again, not ideal, but at least workable
		# possible idea: use kinosearch for this?
		foreach my $domainId (@$domain_ids)
		{
			$return->{$domainId}=[];
			my $domainSql='SELECT locusId FROM Locus2Domain WHERE
				domainId = ?';
		
			my $domainSth=$moDbh->prepare($domainSql);
			$domainSth->execute($domainId);
			my %externalIds;
			while (my $row=$domainSth->fetch)
			{
				$externalIds{$row->[0]} += 1;
			}

			my ($cogInfoId)=$domainId=~/^COG(\d+)$/;
			if ($cogInfoId)
			{
				my $cogSql='SELECT locusId FROM COG WHERE
					cogInfoId = ?';
		
				my $cogSth=$moDbh->prepare($cogSql);

				$cogSth->execute($cogInfoId);
				while (my $row=$cogSth->fetch)
				{
					$externalIds{$row->[0]} += 1;
				}
			}

			my @externalIds=keys %externalIds;
			if (scalar @externalIds)
			{
				my $extIds2fids=$kbMOT->moLocusIds_to_fids(\@externalIds);
				my $domain_fids={};
				foreach my $extId (keys %$extIds2fids)
				{
					# this is an arrayref
					my $fids=$extIds2fids->{$extId};
					map {$domain_fids->{$_} = $_} @$fids;
				}

				my @domain_fids=keys $domain_fids;
				$return->{$domainId} = \@domain_fids;
			}
		}

	}
	
    #END domains_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to domains_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'domains_to_fids');
    }
    return($return);
}




=head2 domains_to_domain_annotations

  $return = $obj->domains_to_domain_annotations($domain_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a string
domains is a reference to a list where each element is a string
domain_id is a string

</pre>

=end html

=begin text

$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a string
domains is a reference to a list where each element is a string
domain_id is a string


=end text



=item Description

domains_to_domain_annotations takes as input a list of domain_ids, and
returns a mapping of each domain_id to its text annotation as provided
by its maintainer (usually retrieved from InterProScan, or from NCBI
for COG).

=back

=cut

sub domains_to_domain_annotations
{
    my $self = shift;
    my($domain_ids) = @_;

    my @_bad_arguments;
    (ref($domain_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"domain_ids\" (value was \"$domain_ids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to domains_to_domain_annotations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'domains_to_domain_annotations');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN domains_to_domain_annotations

	$return={};
	
	my $moDbh=$self->{moDbh};
	my $kbMOT=$self->{kbMOT};

	if (scalar @$domain_ids)
	{
		foreach my $domainId (@$domain_ids)
		{
			$return->{$domainId}='(no description available)';
			my $domainSql='SELECT domainName,iprName FROM DomainInfo WHERE
				domainId = ?';
		
			my $domainSth=$moDbh->prepare($domainSql);
			$domainSth->execute($domainId);
			while (my $row=$domainSth->fetch)
			{
				$return->{$domainId} = $row->[0];
				$return->{$domainId} .=  ' ' . $row->[1] if ($row->[1] and $row->[1] ne 'NULL');
			}

			my ($cogInfoId)=$domainId=~/^COG(\d+)$/;
			if ($cogInfoId)
			{
				my $cogSql='SELECT geneName, description, funCode FROM COGInfo WHERE
					cogInfoId = ?';
		
				my $cogSth=$moDbh->prepare($cogSql);

				$cogSth->execute($cogInfoId);
				while (my $row=$cogSth->fetch)
				{
					$return->{$domainId} = $row->[0] . ' ' . $row->[1] . ' (category ' . $row->[2] . ')';
				}
			}
		}
	}

    #END domains_to_domain_annotations
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to domains_to_domain_annotations:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'domains_to_domain_annotations');
    }
    return($return);
}




=head2 fids_to_ipr

  $return = $obj->fids_to_ipr($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ipr
fid is a string
ipr is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ipr
fid is a string
ipr is a reference to a list where each element is a string


=end text



=item Description

fids_to_ipr takes as input a list of feature ids, and returns
a mapping of each fid to its IPR assignments. These can come from
HMMER or from non-HMM-based InterProScan results.

=back

=cut

sub fids_to_ipr
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_ipr:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ipr');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_ipr

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			$return->{$fid} = [];
			my $iprSql='SELECT DISTINCT locusId,iprId FROM Locus2Ipr WHERE
				locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $iprSth=$moDbh->prepare($iprSql);
			$iprSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$iprSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

		}
	}

    #END fids_to_ipr
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_ipr:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ipr');
    }
    return($return);
}




=head2 fids_to_orthologs

  $return = $obj->fids_to_orthologs($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.orthologs
fid is a string
orthologs is a reference to a list where each element is a ProteinInfo.fid

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.orthologs
fid is a string
orthologs is a reference to a list where each element is a ProteinInfo.fid


=end text



=item Description

fids_to_orthologs takes as input a list of feature ids, and
returns a mapping of each fid to its orthologous fids in
all genomes.

=back

=cut

sub fids_to_orthologs
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_orthologs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_orthologs');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_orthologs

    $return={};
    my $kbMOT=$self->{kbMOT};
    my $moDbh=$self->{moDbh};
    # very crude hack to bypass bad MO dbh-management code
    @Bio::KBase::ProteinInfoService::Browser::DB::dbhStack=({user=>'kbase_dummy',dbh=>$moDbh});
    warn Dumper($fids);
    warn Dumper(@Bio::KBase::ProteinInfoService::Browser::DB::dbhStack);
    my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);
    my $return_temp;

    foreach my $fid (keys %$fids2externalIds) {
	# run the orthologs query for every locusId that was returned for the fid
	foreach my $locusId ( @{$fids2externalIds->{$fid}}) {
	    my $gene = Bio::KBase::ProteinInfoService::Gene::new( locusId => $locusId);
	    my $moOrthologList = $gene->getOrthologListRef();
            $return_temp->{$fid} = {} unless defined( $return_temp->{$fid});
            foreach my $ortholog (@$moOrthologList) {
		$return_temp->{$fid}->{$ortholog->{'locusId_'}} = undef; # Create hash entry with undef placeholder
	    }

	}
    }

    my %moOrthologList;
    @moOrthologList{ map { keys %{$return_temp->{$_}}}  keys %$return_temp } = undef;
    my @OrthologList = keys %moOrthologList;
    my $moOrthologs2fids=$kbMOT->moLocusIds_to_fids( \@OrthologList);
    foreach my $fid ( keys %$return_temp ) {
	my %kbOrthologs;
	foreach my $ortholog ( map { @{$moOrthologs2fids-> {$_}} } keys %{$return_temp->{$fid}} ) {
	    $kbOrthologs{$ortholog} = undef;
	}
	$return->{$fid} = [];
	push @{$return->{$fid}}, keys %kbOrthologs;
    }
		     

    #END fids_to_orthologs
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_orthologs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_orthologs');
    }
    return($return);
}




=head2 fids_to_ec

  $return = $obj->fids_to_ec($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ec
fid is a string
ec is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ec
fid is a string
ec is a reference to a list where each element is a string


=end text



=item Description

fids_to_ec takes as input a list of feature ids, and returns
a mapping of each fid to its Enzyme Commission numbers (EC).

=back

=cut

sub fids_to_ec
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_ec:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ec');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_ec

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			$return->{$fid} = [];

			my $ecSql='SELECT DISTINCT locusId,ecNum FROM Locus2Ec WHERE
				locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $ecSth=$moDbh->prepare($ecSql);
			$ecSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$ecSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

		}
	}
    #END fids_to_ec
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_ec:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ec');
    }
    return($return);
}




=head2 fids_to_go

  $return = $obj->fids_to_go($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.go
fid is a string
go is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.go
fid is a string
go is a reference to a list where each element is a string


=end text



=item Description

fids_to_go takes as input a list of feature ids, and returns
a mapping of each fid to its Gene Ontology assignments (GO).

=back

=cut

sub fids_to_go
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_go:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_go');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_go

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			$return->{$fid} = [];

			my $goSql='SELECT DISTINCT locusId,acc FROM Locus2Go l2g
		       		JOIN term t ON (t.id=l2g.goId)
				WHERE locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $goSth=$moDbh->prepare($goSql);
			$goSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$goSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

		}
	}
    #END fids_to_go
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_go:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_go');
    }
    return($return);
}




=head2 fid_to_neighbors

  $return = $obj->fid_to_neighbors($id, $thresh)

=over 4

=item Parameter and return types

=begin html

<pre>
$id is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float

</pre>

=end html

=begin text

$id is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float


=end text



=item Description

fid_to_neighbor takes as input a single feature id, and
a neighbor score threshold and returns a list of neighbors
where neighbor score >= threshold

=back

=cut

sub fid_to_neighbors
{
    my $self = shift;
    my($id, $thresh) = @_;

    my @_bad_arguments;
    (!ref($id)) or push(@_bad_arguments, "Invalid type for argument \"id\" (value was \"$id\")");
    (!ref($thresh)) or push(@_bad_arguments, "Invalid type for argument \"thresh\" (value was \"$thresh\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fid_to_neighbors:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fid_to_neighbors');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fid_to_neighbors
    return {} unless ($id);
    my $rtemp = $self->fidlist_to_neighbors( [ $id ], $thresh);
    $return = $rtemp->{ $id } || {};
    #END fid_to_neighbors
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fid_to_neighbors:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fid_to_neighbors');
    }
    return($return);
}




=head2 fidlist_to_neighbors

  $return = $obj->fidlist_to_neighbors($fids, $thresh)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float


=end text



=item Description

fidlist_to_neighbors takes as input a list of feature ids, and
a minimal neighbor score, and returns a mapping of each fid to
its neighbors, based on neighbor score >= threshold

=back

=cut

sub fidlist_to_neighbors
{
    my $self = shift;
    my($fids, $thresh) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    (!ref($thresh)) or push(@_bad_arguments, "Invalid type for argument \"thresh\" (value was \"$thresh\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fidlist_to_neighbors:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fidlist_to_neighbors');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fidlist_to_neighbors

    return {} unless (scalar @$fids);

    my $kbMOT=$self->{kbMOT};
    my $dbh =$self->{moDbh};
    my $kbCDM =$self->{kbCDM};
    my $fid2locus=$kbMOT->fids_to_moLocusIds($fids);
    my $fid2genome = $kbCDM->fids_to_genomes( $fids);

    my $neighbor1_sql = $dbh->prepare( q{ select m.locusId, n.score from MOGMember m, MOGNeighborScores n where n.mog2 = ? and n.score >= ? and n.mog1 = m.mogId and m.taxonomyId = ? });
    my $neighbor2_sql = $dbh->prepare( q{ select m.locusId, n.score from MOGMember m, MOGNeighborScores n where n.mog1 = ? and n.score >= ? and n.mog2 = m.mogId and m.taxonomyId = ? });
    $return = {};
    my $neighbors = {};
    foreach my $fid ( keys %$fid2locus) {
	my $get_mogId= $dbh->prepare( sprintf "select mogId, taxonomyId from MOGMember where locusId in ( %s )",
	    join( ",", map { "?" } @{$fid2locus->{$fid}}));
	my $mogIds = $dbh->selectall_arrayref( $get_mogId, {}, @{$fid2locus->{$fid}});
	foreach my $mogId ( @$mogIds) {
	    my $n1 = $dbh->selectall_arrayref( $neighbor1_sql, {}, ($mogId->[0], $thresh,$mogId->[1]));
	    my $n2 = $dbh->selectall_arrayref( $neighbor2_sql, {}, ($mogId->[0], $thresh,$mogId->[1]));
	    # Grab the locusIds of all the neighbors and translate them into fids
	    my @locusIds = map { $_->[0] } ( @$n1, @$n2);
	    my $locus2fids = $kbMOT->moLocusIds_to_fids(\@locusIds);
	    my %nfids;
	    # dedupe locus->fids to avoid redundant queries
	    foreach my $l ( keys %$locus2fids) {
		foreach my $f ( @{$locus2fids->{$l}}) {
		    $nfids{ $f } = 1;
		}
	    }
	    my @nfids = keys %nfids;
	    my $ngenomes = $kbCDM->fids_to_genomes( \@nfids);
	    # only return the results where the neighbor genome matches $fid genome
	    foreach my $neighbor ( @$n1, @$n2) {
		my $locusId = $neighbor->[0];
		foreach my $nfid ( @{$locus2fids->{$locusId}}) {
		    if ($ngenomes->{$nfid} eq $fid2genome->{$fid}) {
			if (! defined($return->{$fid})) {
			    $return->{$fid} = { $nfid => $neighbor->[1] };
			} else {
			    $return->{$fid}->{$nfid} = $neighbor->[1];
			}
		    }
		}
	    }
	}
    }
    #END fidlist_to_neighbors
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fidlist_to_neighbors:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fidlist_to_neighbors');
    }
    return($return);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 fid

=over 4



=item Description

A fid is a unique identifier of a feature.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 domain_id

=over 4



=item Description

A domain_id is an identifier of a protein domain or family
(e.g., COG593, TIGR00362). Most of these are stable identifiers
that come from external curated libraries, such as COG or InterProScan,
but some may be unstable identifiers that come from automated
analyses like FastBLAST. (The current implementation includes only
COG and InterProScan HMM libraries, such as TIGRFam and Pfam.)


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 neighbor_threshold

=over 4



=item Description

A neighbor_threshold is a floating point number indicating a bound
for the neighbor score


=item Definition

=begin html

<pre>
a float
</pre>

=end html

=begin text

a float

=end text

=back



=head2 neighbor

=over 4



=item Description

Neighbor is a hash of fids to a neighbor score


=item Definition

=begin html

<pre>
a reference to a hash where the key is a ProteinInfo.fid and the value is a float
</pre>

=end html

=begin text

a reference to a hash where the key is a ProteinInfo.fid and the value is a float

=end text

=back



=head2 domains

=over 4



=item Description

Domains are a list of domain_ids.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 Hit

=over 4



=item Description

A Hit is a description of a match to another object (a fid,
a gene family, an HMM).  It is a structure with the following
fields:
        id: the common identifier of the object (e.g., a fid, an HMM accession)
        subject_db: the source database of the original hit (e.g., KBase for fids, TIGRFam, Pfam, COG)
        description: a human-readable textual description of the object (might be empty)
        query_begin: the start of the hit in the input gene sequence
        query_end: the end of the hit in the input gene sequence
        subject_begin: the start of the hit in the object gene sequence
        subject_end: the end of the hit in the object gene sequence
        score: the score (if provided) of the hit to the object
        evalue: the evalue (if provided) of the hit to the object


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
subject_db has a value which is a string
description has a value which is a string
query_begin has a value which is an int
query_end has a value which is an int
subject_begin has a value which is an int
subject_end has a value which is an int
score has a value which is a float
evalue has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
subject_db has a value which is a string
description has a value which is a string
query_begin has a value which is an int
query_end has a value which is an int
subject_begin has a value which is an int
subject_end has a value which is an int
score has a value which is a float
evalue has a value which is a float


=end text

=back



=head2 ec

=over 4



=item Description

ECs are a list of Enzyme Commission identifiers.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 go

=over 4



=item Description

GOs are a list of Gene Ontology identifiers.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 ipr

=over 4



=item Description

IPRs are a list of InterPro identifiers.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 operon

=over 4



=item Description

An operon is represented by a list of fids
which make up that operon.  The order within the list is not
defined; the fids_to_locations method can report on the
order of the fids in the operon.


=item Definition

=begin html

<pre>
a reference to a list where each element is a ProteinInfo.fid
</pre>

=end html

=begin text

a reference to a list where each element is a ProteinInfo.fid

=end text

=back



=head2 orthologs

=over 4



=item Description

Orthologs are a list of fids which are orthologous to a given fid.


=item Definition

=begin html

<pre>
a reference to a list where each element is a ProteinInfo.fid
</pre>

=end html

=begin text

a reference to a list where each element is a ProteinInfo.fid

=end text

=back



=cut

1;
