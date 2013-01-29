package Bio::KBase::ProteinInfoService::Browser::DB;
require Exporter;

use strict;
use DBI;
use Time::HiRes;
use Carp;

use Bio::KBase::ProteinInfoService::Browser::HTML;
use Bio::KBase::ProteinInfoService::Browser::Defaults;

use vars '$VERSION';
use vars qw($defaults);
$VERSION = 0.01;

our @ISA = qw(Exporter);
our @EXPORT = qw(dbConnect dbDisconnect dbSql dbSqlResults dbHandle dbQuote dbSetDebug);
our @dbhStack;
our $DEBUG = 0;

sub dbConnect(;$$$$)
{
	my $host = shift;
	my $user = shift;
	my $pw = shift;
	my $db = shift;

	$host = $defaults->{dbHost}
		if ( !defined($host) );
	$user = $defaults->{dbUser}
		if ( !defined($user) );
	$pw = $defaults->{dbPassword}
		if ( !defined($pw) );
	$db = $defaults->{dbDatabase}
		if ( !defined($db) );
	# hack to do nopassword-connection
	$pw=undef if ($pw eq 'undef');

	my $dsn = "DBI:" . $defaults->{dbType} . ":${db}:${host}";
	my $dbh = DBI->connect( $dsn, $user, $pw );

	if ( !defined( $dbh ) )
	{
		htmlError( "Unable to connect to database server '$host' and/or schema '$db'" );
		exit;
	}

	my %params = ();
	$params{host} = $host;
	$params{user} = $user;
	$params{db} = $db;
	$params{dbh} = $dbh;

	push( @dbhStack, \%params );

	carp "DB.pm: DBI->connect( '$dsn', '$user', '...' ) => " . scalar(@dbhStack) . " total connections"
		if ( $DEBUG );

	dbSql( "USE $db" )
		if (length($db) > 0);
}

sub dbSetDebug($) {
    my $debug = shift;
    $DEBUG = $debug;
}

sub dbDisconnect
{
	my $params = pop( @dbhStack );
	$params->{dbh}->disconnect;

	print STDERR "DB.pm: DBI->disconnect => " . scalar(@dbhStack) . " total connections left\n"
		if ( $DEBUG );
}

sub isConnected
{
	return ( (scalar( @dbhStack ) > 0) &&
			defined( $dbhStack[-1]->{dbh} ) );
}

sub dbHandle
{
	return $dbhStack[-1]->{dbh}
		if ( scalar( @dbhStack ) > 0 );

	return undef;
}

sub dbQuote($)
{
	my $text = shift;

	return $dbhStack[-1]->{dbh}->quote( $text )
		if ( scalar( @dbhStack ) > 0 );

	return $text;
}

our($dbQueryCumulative) = 0;

sub dbSql($)
{
	my $query = shift;

	print STDERR "DB.pm: query: [$query]\n"
		if ( $DEBUG );

	return
		if ( !defined( $query ) );

	if ( scalar( @dbhStack ) > 0 )
	{
		my $dbh = $dbhStack[-1]->{dbh};
		my $start;
		$start = [ Time::HiRes::gettimeofday( ) ] if $DEBUG >= 10;

		my $sth = $dbh->prepare( $query ) ||
			htmlError( "SQL prepare failed: '$query'<BR>DBI error: " . $dbh->errstr );
		$sth->execute ||
			htmlError( "SQL execute failed: '$query'<BR>DBI error: " . $dbh->errstr );
		$sth->finish;
		undef( $sth );
		if ($DEBUG >= 10) {
		    my $elapsed = Time::HiRes::tv_interval( $start ); 
		    $dbQueryCumulative += $elapsed;
		    print STDERR "Query took $elapsed seconds (dbSql cumulative $dbQueryCumulative)\n";
		}
	} else {
		htmlError( "Cannot issue SQL query before connecting to database server." );
		exit;
	}
}

sub dbSqlResults($;$)
{
	my $query = shift;
	my $type = shift;

	return
		if ( !defined( $query ) );
	$type = "h"
		if ( !defined( $type ) );

	carp "DB.pm: query: [$query]"
		if ( $DEBUG );

	if ( scalar( @dbhStack ) > 0 )
	{
		my $dbh = $dbhStack[-1]->{dbh};
		carp 'DB.pm: dbname: '.$dbh->{Name}
			if ( $DEBUG );
		my $start;
		$start = [ Time::HiRes::gettimeofday( ) ] if $DEBUG >= 10;

		my $sth = $dbh->prepare( $query ) ||
			htmlError( "SQL prepare failed: '$query'<BR>DBI error: " . $dbh->errstr );
		$sth->execute ||
			htmlError( "SQL execute failed: '$query'<BR>DBI error: " . $dbh->errstr );

		my $resultsRef;
		if ( $type eq 'h' )
		{
			$resultsRef = $sth->fetchall_arrayref( { } );
		} else {
			$resultsRef = $sth->fetchall_arrayref( );
		}

		$sth->finish;
		undef( $sth );

		if ($DEBUG >= 10) {
		    my $elapsed = Time::HiRes::tv_interval( $start ); 
		    $dbQueryCumulative += $elapsed;
		    print STDERR "Query took $elapsed seconds (dbSql cumulative $dbQueryCumulative)\n";
		}

		if ( $type eq 'hashList' )
		{
			my %h;
			foreach ( @{$resultsRef} )
			{
				my ($from,$to) = @$_;
				$h{$from} = [] unless exists $h{$from};
				push( @{ $h{$from} }, $to );
			}
			return \%h;
		}

		return @{$resultsRef};
	} else {
		htmlError( "Cannot issue SQL query before connecting to database server." );
		exit;
	}
}

1;
