package Bio::KBase::ProteinInfoService::Impl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

Operon

=head1 DESCRIPTION

This module provides common operations related to operons.
Additional operon related operations can be found in the
CDMI api such as those related to atomic regulons

=cut

#BEGIN_HEADER

use Bio::KBase;
use Bio::KBase::MOTranslationService::Client;
use DBI;
use ContextAdapter;

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

	my $kb = Bio::KBase->new();
	my $kbIdServer = $kb->id_server();
	my $kbMOT = Bio::KBase::MOTranslationService::Client->new('http://localhost:7061');
	my $moDbh=DBI->connect("DBI:mysql:genomics:pub.microbesonline.org",'guest','guest');

	$self->{kbIdServer}=$kbIdServer;
	$self->{kbMOT}=$kbMOT;
	$self->{moDbh}=$moDbh;

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
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an operon
fid is a string
operon is a reference to a list where each element is a fid

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an operon
fid is a string
operon is a reference to a list where each element is a fid


=end text



=item Description

This function takes as input a list of feature
ids and returns a mapping of the fid to the operon
in which it is found

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

    my $ctx = $Bio::KBase::OperonService::Service::CallContext;
    my($return);
    #BEGIN fids_to_operons

	$return={};

	if (scalar @$fids)
	{
		my $ctxA = ContextAdapter->new($ctx);
		my $user_token = $ctxA->user_token();

#		my $kbIdServer=$self->{kbIdServer};
		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

#		my $externalIds=$kbIdServer->kbase_ids_to_external_ids($fids);
		my $externalIds=$kbMOT->fids_to_moLocusIds($fids);

		my $operons={};
		foreach my $kbId (keys %$externalIds)
		{
			#stolen from Gene.pm
			my $operonSql='SELECT o2.locusId FROM Locus2Operon o1, Locus2Operon o2
                                                    WHERE o1.locusId=? AND o1.tuId=o2.tuId
                                                    GROUP BY o2.locusId';
			# be lazy: just look at the first MOL returned
			# [0] is the external db; should check if it's MOL:Feature
			my $operonLocusIdList=$moDbh->selectcol_arrayref($operonSql,{},$externalIds->{$kbId}[1]);
			my @kbaseIds=$kbMOT->moLocusIds_to_fids($operonLocusIdList);
			#my @kbaseIds=values %{$kbIdServer->external_ids_to_kbase_ids('MOL:Feature',$operonLocusIdList)};
			$operons->{$kbId}=\@kbaseIds;
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

A fid is a unique identifier of a feature


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



=head2 operon

=over 4



=item Description

An operon is represented by a list of fids
in that operon.


=item Definition

=begin html

<pre>
a reference to a list where each element is a fid
</pre>

=end html

=begin text

a reference to a list where each element is a fid

=end text

=back



=cut

1;
