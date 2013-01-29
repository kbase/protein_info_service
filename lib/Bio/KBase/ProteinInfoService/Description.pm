package Bio::KBase::ProteinInfoService::Description;
require Exporter;


use strict;
use Bio::KBase::ProteinInfoService::GenomicsUtils;


sub new($;$;$;$;$;$);
# Constructor for Description object. Returns Description object.
# Parameters:
#   descriptionId, description, created, source, locusId
   

sub description();
sub created();
sub source();
sub locusId();
sub version();

sub new($;$;$;$;$;$)
{
    my $self = {};
    bless $self;
    $self->{descriptionId_} = shift;
    $self->{description_} = shift;
    $self->{created_} = shift;
    $self->{source_} = shift;
    $self->{locusId_} = shift;
    $self->{version_} = shift;

    return($self);
}


sub description()
{
    my $self = shift;
    return $self->{description_};

}

sub created()
{
    my $self = shift;
    return $self->{created_};
}

sub source()
{
    my $self = shift;
    return $self->{source_};
}

sub locusId()
{
    my $self = shift;
    return $self->{locusId_};
}

sub version()
{
    my $self = shift;
    return $self->{version_};
}

sub toString()
{
    my $self = shift;
    return "[".$self->{locusId_}."] ".$self->{description_};
}

sub DESTROY() 
{
    
}

1;
