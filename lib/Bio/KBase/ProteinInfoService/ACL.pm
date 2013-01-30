package ACL;
require Exporter;

use strict;
use Bio::KBase::ProteinInfoService::Browser::DB;
use Bio::KBase::ProteinInfoService::Browser::Defaults;
use Bio::KBase::ProteinInfoService::Browser::HTML;

use vars '$VERSION';
use vars qw($defaults $jobStatus);
$VERSION = 0.01;

our @ISA = qw(Exporter);
our @EXPORT = qw(isOwner isGroupMember isSysAdmin userGroups userGroupsDetail resourceListRead resourceRead resourceWrite resourceAdmin resourceACL userShares userResources groupsResources userGroupsResources addUserACL addGroupACL resourceACLMatrix aclMatrixTable cartsForGene);

sub aclMatrixTable
{
	my $resourceId = shift;
	my $resourceType = shift;
	my $userId = shift;
	my $entries = resourceACLMatrix( $resourceId, $resourceType, $userId );

	my $aclNumMap = "";
	my $aclMatrix = "";
	my $aclCount = scalar( @{$entries} );
	my $count = 1;

	$aclCount--
		if ( (scalar(@{$entries}) > 0) && exists( $entries->[0]->{owner} ) );

	my $userAdmin = resourceAdmin( $userId, $resourceId, $resourceType );

	foreach my $e ( @{$entries} )
	{
		if ( exists( $e->{owner} ) )
		{
			$aclMatrix .= "<tr>\n\t<td><nobr>" . $e->{name} . "</nobr></td>\n\t<td colspan=\"3\"><center><i> -- Resource Owner -- </i></center></td>\n</tr>\n";
		} else {
			my $readChecked = ( $e->{read} ) ? " CHECKED" : "";
			my $writeChecked = ( $e->{write} ) ? " CHECKED" : "";
			my $adminChecked = ( $e->{admin} ) ? " CHECKED" : "";
			my $disable = ( !$userAdmin ) ? " DISABLED" : "";
			$aclMatrix .= "<tr>\n\t<td><nobr>" . ( ( $e->{isGroup} ) ? "Group" : "User" ) . ": " . $e->{name} . "</nobr></td>\n\t<td><center><input type=\"checkbox\" name=\"read_${count}\" value=\"1\"${readChecked}${disable}></center></td>\n\t<td><center><input type=\"checkbox\" name=\"write_${count}\" value=\"1\"${writeChecked}${disable}></center></td>\n\t<td><center><input type=\"checkbox\" name=\"admin_${count}\" value=\"1\"${adminChecked}${disable}></center></td>\n</tr>\n";
			$aclNumMap .= "<input type=\"hidden\" name=\"acl_${count}\" value=\"" . $e->{requesterId} . "," . ( ( $e->{isGroup} ) ? "group" : "user" ) . "\">\n";
			$count++;
		}
	}

	return ($aclCount, $aclNumMap, $aclMatrix);
}

sub resourceACLMatrix
{
	my $resourceId = shift;
	my $resourceType = shift;
	my $userId = shift;
	my @entries = ();

	# Owner
	if ( $resourceType eq 'cart' )
	{
		my $query = "SELECT u.userId AS requesterId, u.name FROM genomics_test.Users u LEFT JOIN genomics_test.Carts c ON u.userId = c.userId WHERE c.cartId = '$resourceId' AND c.active = '1'";
		@entries = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
		if ( scalar(@entries) > 0 )
		{
			$entries[0]->{owner} = 1;
			$entries[0]->{read} = 1;
			$entries[0]->{write} = 1;
			$entries[0]->{admin} = 1;
		}
	} elsif ( $resourceType eq 'job' )
	{
		my $query = "SELECT u.userId AS requesterId, u.name FROM genomics_test.Users u LEFT JOIN genomics_test.Jobs j ON u.userId = j.userId WHERE j.jobId = '$resourceId'";
		@entries = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
		if ( scalar(@entries) > 0 )
		{
			$entries[0]->{owner} = 1;
			$entries[0]->{read} = 1;
			$entries[0]->{write} = 1;
			$entries[0]->{admin} = 1;
		}
#	} elsif ( $resourceType eq 'uarray' )
#	{
#		my $query = "SELECT u.userId AS requesterId, u.name FROM Users u LEFT JOIN microarray.Exp m ON u.userId = m.userId WHERE m.id = '$resourceId'";
#		@entries = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
#		if ( scalar(@entries) > 0 )
#		{
#			$entries[0]->{owner} = 1;
#			$entries[0]->{read} = 1;
#			$entries[0]->{write} = 1;
#			$entries[0]->{admin} = 1;
#		}
	}

	# Users
	my $query = "SELECT u.userId AS requesterId, u.name, a.read, a.write, a.admin FROM genomics_test.ACL a LEFT JOIN genomics_test.Users u ON a.requesterId = u.userId WHERE a.requesterType = 'user' AND resourceId = '$resourceId' AND resourceType = '$resourceType'";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	@entries = ( @entries, @results );

	# Groups
	$query = "SELECT g.groupId AS requesterId, 1 AS isGroup, g.name, a.read, a.write, a.admin FROM genomics_test.ACL a LEFT JOIN genomics_test.Groups g ON a.requesterId = g.groupId WHERE a.requesterType = 'group' AND resourceId = '$resourceId' AND resourceType = '$resourceType' ORDER BY g.groupId";
	@results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	@entries = ( @entries, @results );

	return \@entries;
}

sub setUserACL
{
	my $userId = shift;
	my $resourceId = shift;
	my $resourceType = shift;
	my $read = shift;
	my $write = shift;
	my $admin = shift;

	if ( ($read+$write+$admin) > 0 )
	{
		my $query = "SELECT `read` FROM genomics_test.ACL WHERE requesterId = '$userId' AND requesterType = 'user' AND resourceId = '$resourceId' AND resourceType = '$resourceType'";
		my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );

		if ( scalar(@results) > 0 )
		{
			# Do an update
			$query = "UPDATE genomics_test.ACL SET `read` = '$read', `write` = '$write', admin = '$admin' WHERE requesterId = '$userId' AND requesterType = 'user' AND resourceId = '$resourceId' AND resourceType = '$resourceType' LIMIT 1";
			Bio::KBase::ProteinInfoService::Browser::DB::dbSql( $query );
		} else {
			# Do an insert
			$query = "INSERT INTO genomics_test.ACL (requesterId, requesterType, resourceId, resourceType, `read`, `write`, admin) VALUES ('$userId', 'user', '$resourceId', '$resourceType', '$read', '$write', '$admin')";
			Bio::KBase::ProteinInfoService::Browser::DB::dbSql( $query );
		}
	} else {
		# remove ACL entry
		my $query = "DELETE FROM genomics_test.ACL WHERE requesterId = '$userId' AND requesterType = 'user' AND resourceId = '$resourceId' AND resourceType = '$resourceType'";
		Bio::KBase::ProteinInfoService::Browser::DB::dbSql( $query );
	}
}

sub setGroupACL
{
	my $groupId = shift;
	my $resourceId = shift;
	my $resourceType = shift;
	my $read = shift;
	my $write = shift;
	my $admin = shift;

	if ( ($read+$write+$admin) > 0 )
	{
		my $query = "SELECT `read` FROM genomics_test.ACL WHERE requesterId = '$groupId' AND requesterType = 'group' AND resourceId = '$resourceId' AND resourceType = '$resourceType'";
		my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );

		if ( scalar(@results) > 0 )
		{
			# Do an update
			$query = "UPDATE genomics_test.ACL SET `read` = '$read', `write` = '$write', admin = '$admin' WHERE requesterId = '$groupId' AND requesterType = 'group' AND resourceId = '$resourceId' AND resourceType = '$resourceType' LIMIT 1";
			Bio::KBase::ProteinInfoService::Browser::DB::dbSql( $query );
		} else {
			# Do an insert
			$query = "INSERT INTO genomics_test.ACL (requesterId, requesterType, resourceId, resourceType, `read`, `write`, admin) VALUES ('$groupId', 'group', '$resourceId', '$resourceType', '$read', '$write', '$admin')";
			Bio::KBase::ProteinInfoService::Browser::DB::dbSql( $query );
		}
	} else {
		# remove ACL entry
		my $query = "DELETE FROM genomics_test.ACL WHERE requesterId = '$groupId' AND requesterType = 'group' AND resourceId = '$resourceId' AND resourceType = '$resourceType'";
		Bio::KBase::ProteinInfoService::Browser::DB::dbSql( $query );
	}
}

sub userGroupsResources
{
	my $userId = shift;
	my $userGroupsRef = ACL::userGroups( $userId );

	return []
		if ( scalar( @{$userGroupsRef} ) < 1 );

	return groupsResources( @{$userGroupsRef} );
}

sub groupsResources
{
	return []
		if ( scalar(@_) < 1 );
	my $inGroups = "('" . join("','", @_) . "')";

	my $query = "SELECT a.resourceId, a.resourceType, c.name, u.name AS sharedBy, CONCAT('Group: ', g.name) AS sharedTo, a.read, a.write, a.admin FROM genomics_test.ACL a LEFT JOIN genomics_test.Carts c ON (a.resourceId = c.cartId) LEFT JOIN genomics_test.Users u ON (c.userId = u.userId) LEFT JOIN genomics_test.Groups g ON (a.requesterId = g.groupId) WHERE a.requesterId IN $inGroups AND a.requesterType = 'group' AND a.resourceType = 'cart' AND c.active = 1";
	my @resources = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );

	$query = "SELECT a.resourceId, a.resourceType, j.jobName, j.jobType, u.name AS sharedBy, CONCAT('Group: ', g.name) AS sharedTo, a.read, a.write, a.admin FROM genomics_test.ACL a LEFT JOIN genomics_test.Jobs j ON (a.resourceId = j.jobId) LEFT JOIN genomics_test.Users u ON (j.userId = u.userId) LEFT JOIN genomics_test.Groups g ON (a.requesterId = g.groupId) WHERE a.requesterId IN $inGroups AND a.requesterType = 'group' AND a.resourceType = 'job' AND j.status = '$jobStatus->{DONE}'";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	@resources = ( @resources, @results );

	return \@resources;
}

sub userResources
{
	my $userId = shift;

	my $query = "SELECT a.resourceId, a.resourceType, c.name, u.name AS sharedBy, u2.name AS sharedTo, a.read, a.write, a.admin FROM genomics_test.ACL a LEFT JOIN genomics_test.Carts c ON (a.resourceId = c.cartId) LEFT JOIN genomics_test.Users u ON (c.userId = u.userId) LEFT JOIN genomics_test.Users u2 ON (a.requesterId = u2.userId) WHERE a.requesterId = '$userId' AND a.requesterType = 'user' AND a.resourceType = 'cart' AND c.active = 1";
	my @resources = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );

	$query = "SELECT a.resourceId, a.resourceType, j.jobName, j.jobType, u.name AS sharedBy, u2.name AS sharedTo, a.read, a.write, a.admin FROM genomics_test.ACL a LEFT JOIN genomics_test.Jobs j ON (a.resourceId = j.jobId) LEFT JOIN genomics_test.Users u ON (j.userId = u.userId) LEFT JOIN genomics_test.Users u2 ON (a.requesterId = u2.userId) WHERE a.requesterId = '$userId' AND a.requesterType = 'user' AND a.resourceType = 'job' AND j.status = '$jobStatus->{DONE}'";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	@resources = ( @resources, @results );

	return \@resources;
}

sub userShares
{
	my $userId = shift;
	my @shares = ();

	# Carts
	my $query = "SELECT a.requesterId, a.requesterType, a.resourceId, a.resourceType, c.name, a.read, a.write, a.admin FROM genomics_test.Carts c JOIN genomics_test.ACL a ON a.resourceId = c.cartId WHERE a.resourceType = 'cart' AND c.userId = '$userId' AND c.active = '1' GROUP BY a.resourceId";
	@shares = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );

	# Jobs
	$query = "SELECT a.requesterId, a.requesterType, a.resourceId, a.resourceType, j.jobName, j.jobType, a.read, a.write, a.admin FROM genomics_test.Jobs j JOIN genomics_test.ACL a ON a.resourceId = j.jobId WHERE a.resourceType = 'job' AND j.userId = '$userId' GROUP BY a.resourceId";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );

	@shares = ( @shares, @results );
	return \@shares;
}

sub resourceACL
{
	my $userId = shift;
	my $resourceId = shift;
	my $resourceType = shift;
	my $access = shift;	# "read", "write", "admin"
	my $acc = substr( $access, 0, 1 );

	if ( $acc eq 'r' )
	{
		return resourceRead( $userId, $resourceId, $resourceType );
	} elsif ( $acc eq 'w' )
	{
		return resourceWrite( $userId, $resourceId, $resourceType );
	} elsif ( $acc eq 'a' )
	{
		return resourceAdmin( $userId, $resourceId, $resourceType );
	}

	return 0;
}

# new sub resourceListRead kkeller
# takes a list of resourceIds (of the same resourceType) and returns a
# list of resources that are readable by userId
# switches calling order around from resourceRead, but
# I want to be able to receive a list
#
# Checks if you are the owner ONLY for jobs
# May not matter for other objects (e.g. we do create an ACL to give you access
#	to your own carts)
#
sub resourceListRead
{
        my $userId = shift;
        my $resourceType = shift;
        my @resourceIdList = @_;
        return undef unless @resourceIdList;
        my $resourceIdVals = '(' . join(',', @resourceIdList) . ')';

        my $userGroupsRef = userGroups( $userId );
        my $userGroupsVals = '(' . join(',', @{$userGroupsRef}) . ')';

        my $query = "SELECT ACL.resourceId FROM genomics_test.ACL
                WHERE resourceId IN $resourceIdVals
                AND resourceType = '$resourceType'
                AND (
                        (requesterType = 'user' AND requesterId = $userId)
                        OR (requesterType = 'group' AND requesterId IN $userGroupsVals)
                ) AND ACL.read = 1";

        my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	my %readable = map {$_->{resourceId} => 1} @results;

	# now check for owners, for jobs or carts
	if ($resourceType eq "job") {
	    my @owned = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults("SELECT jobId FROM genomics_test.Jobs"
						  . " WHERE userId=$userId"
						  . " AND jobId IN $resourceIdVals");
	    foreach my $row (@owned) {
		$readable{$row->{jobId}} = 1;
	    }
	} elsif ($resourceType eq "cart") {
	    my @owned = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults("SELECT cartId FROM genomics_test.Carts"
						  . " WHERE userId=$userId"
						  . " AND cartId IN $resourceIdVals");
	    foreach my $row (@owned) {
		$readable{$row->{cartId}} = 1;
	    }
	}

        my @readableResourceIds = grep {exists $readable{$_}} @resourceIdList;
        return @readableResourceIds;
}

sub resourceRead
{
	my $userId = shift;
	my $resourceId = shift;
	my $resourceType = shift;

	return 1
		if ( isOwner( $resourceId, $resourceType, $userId ) );
	my $userGroupsRef = userGroups( $userId );
	my $userGroupsVals = "('" . join("','", @{$userGroupsRef}) . "')";

	my $query = "SELECT ACL.read FROM genomics_test.ACL WHERE resourceId = '$resourceId' AND resourceType = '$resourceType' AND ((requesterType = 'user' AND requesterId = '$userId') OR (requesterType = 'group' AND requesterId IN $userGroupsVals)) AND ACL.read = '1'";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( scalar(@results) > 0 );
}

# given a list of desired taxId, return back a list of only
# those taxIds that are readable by this user
sub taxListFilterReadable
{
	my $userId = shift;
	$userId = defined($userId) ?
			int($userId) :
			0;
	my $taxIdVals = "('" . join("','", @_) . "')";
	my $userGroups = userGroups( $userId );
	# always include the public group
	my $userGroupVals = "('" . join("','", @{$userGroups},1) . "')";

	my $query = "SELECT DISTINCT(s.taxonomyId) FROM genomics_test.Scaffold s JOIN genomics_test.ACL a ON (s.scaffoldId = a.resourceId AND a.resourceType = 'scaffold') WHERE s.taxonomyId IN $taxIdVals AND s.isActive = 1 AND ( (a.requesterType = 'group' AND a.requesterId IN $userGroupVals) OR (a.requesterType = 'user' AND a.requesterId = '$userId') ) AND a.read = 1";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	my @taxIds = ();

	foreach my $r ( @results )
	{
		push( @taxIds, $r->{taxonomyId} );
	}

	return @taxIds;
}

sub taxReadable { # returns a hash of taxonomyId -> [ #scaffolds ]
    my $userId = shift;
    my $userGroupsRef = userGroups( $userId );
    my $userGroupsVals = "('" . join("','", @{$userGroupsRef}) . "')";
    
    my $query = qq{SELECT s.taxonomyId, count(DISTINCT scaffoldId) FROM genomics_test.ACL a, genomics_test.Scaffold s
		       WHERE a.resourceType='scaffold'
		       AND ((a.requesterType='group' AND a.requesterId IN $userGroupsVals)
			    OR (a.requesterType='user' AND a.requesterId='$userId'))
		       AND a.read='1'
		       AND a.resourceId=s.scaffoldId
		       AND s.isActive=1
		       GROUP BY s.taxonomyId};
    return Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults($query, 'hashList');
}
			    
sub taxReadableByTaxId { # returns a hash of taxonomyId -> 1; not sure if
		# number of scaffolds will make a difference
    my $userId = shift;
    my $userGroupsRef = userGroups( $userId );
    my $userGroupsVals = "('" . join("','", @{$userGroupsRef}) . "')";
    
    my $query = qq{
    SELECT a.resourceId, 1 FROM genomics_test.ACL a
		       WHERE a.resourceType='taxonomyId'
		       AND ((a.requesterType='group' AND a.requesterId IN $userGroupsVals)
			    OR (a.requesterType='user' AND a.requesterId='$userId'))
		       AND a.read='1'
		       ORDER BY resourceId};
    return Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults($query, 'hashList');
}
			    
sub resourceWrite
{
	my $userId = shift;
	my $resourceId = shift;
	my $resourceType = shift;

	return 1
		if ( isOwner( $resourceId, $resourceType, $userId ) );
	my $userGroupsRef = userGroups( $userId );
	my $userGroupsVals = "('" . join("','", @{$userGroupsRef}) . "')";

	my $query = "SELECT ACL.write FROM genomics_test.ACL WHERE resourceId = '$resourceId' AND resourceType = '$resourceType' AND ((requesterType = 'user' AND requesterId = '$userId') OR (requesterType = 'group' AND requesterId IN $userGroupsVals)) AND ACL.write = '1'";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( scalar(@results) > 0 );
}

sub resourceAdmin
{
	my $userId = shift;
	my $resourceId = shift;
	my $resourceType = shift;

	return 1
		if ( isOwner( $resourceId, $resourceType, $userId ) );
	my $userGroupsRef = userGroups( $userId );
	my $userGroupsVals = "('" . join("','", @{$userGroupsRef}) . "')";

	my $query = "SELECT ACL.admin FROM genomics_test.ACL WHERE resourceId = '$resourceId' AND resourceType = '$resourceType' AND ((requesterType = 'user' AND requesterId = '$userId') OR (requesterType = 'group' AND requesterId IN $userGroupsVals)) AND ACL.admin = '1'";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( scalar(@results) > 0 );
}

sub userGroupsDetail
{
	my $userId = shift;

	# userId 0 is a wildcard for all users (such as for use in public groups)
	my $query = "SELECT g.groupId, g.name, g.description, g.adminUserId FROM genomics_test.GroupUsers gu LEFT JOIN genomics_test.Groups g ON (gu.groupId = g.groupId) WHERE (gu.userId = '$userId' OR gu.userId = '0') AND gu.active = '1' GROUP BY g.groupId";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );

	return \@results;
}

sub userGroups
{
	my $userId = shift;

	# userId 0 is a wildcard for all users (such as for use in public groups)
	my $query = "SELECT DISTINCT(groupId) AS groupId FROM genomics_test.GroupUsers WHERE (userId = '$userId' OR userId = '0' OR groupId=1) AND active = '1'";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	my @groupIds = ();
	foreach my $r ( @results )
	{
		push( @groupIds, $r->{groupId} );
	}
	return \@groupIds;
}

sub isGroupMember
{
	my $groupId = shift;
	my $userId = shift;

	# userId 0 is a wildcard for all users (such as for use in public groups)
	my $query = "SELECT groupId FROM genomics_test.GroupUsers WHERE groupId = '$groupId' AND (userId = '$userId' OR userId = '0') AND active = '1' LIMIT 1";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( (scalar(@results) > 0) && ($results[0]->{groupId} eq $groupId) );
}

sub isOwner
{
	my $resourceId = shift;
	my $resourceType = shift;
	my $userId = shift;

	if ( $resourceType eq 'cart' )
	{
		return isCartOwner( $resourceId, $userId );
	} elsif ( $resourceType eq 'job' )
	{
		return isJobOwner( $resourceId, $userId );
	} elsif ( $resourceType eq 'uarray' )
	{
		return isuArrayOwner( $resourceId, $userId );
	}

	return 0;
}

sub isuArrayOwner
{
	return 0;
	my $microarrayId = shift;
	my $userId = shift;

	my $query = "SELECT id FROM microarray.Exp WHERE id = '$microarrayId' AND userId = '$userId' LIMIT 1";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( (scalar(@results) > 0) && ($results[0]->{microarrayId} eq $microarrayId) );
}

sub isSysAdmin
{
	my $userId = shift;

	# nothing but digits prevents sql injection
	$userId =~ s/\D+//g;
	my $query = "SELECT userId FROM genomics_test.Users WHERE userId = '$userId' AND isSysAdmin = 1 LIMIT 1";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( scalar(@results) > 0 );
}

sub isCartOwner
{
	my $cartId = shift;
	my $userId = shift;

	my $query = "SELECT cartId FROM genomics_test.Carts WHERE cartId = '$cartId' AND userId = '$userId' AND active = '1' LIMIT 1";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( (scalar(@results) > 0) && ($results[0]->{cartId} eq $cartId) );
}

sub isJobOwner
{
	my $jobId = shift;
	my $userId = shift;

	my $query = "SELECT jobId FROM genomics_test.Jobs WHERE jobId = '$jobId' AND userId = '$userId' LIMIT 1";
	my @results = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults( $query );
	return ( (scalar(@results) > 0) && ($results[0]->{jobId} eq $jobId) );
}

# Given a locusId and a userId, list carts that contain the locusId and
# and that the user has access to
sub cartsForGene
{
    my $locusId = shift;
    my $userId = shift;

    my @relCarts = map {$_->{cartId}} Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults("SELECT cartId FROM genomics_test.Carts"
								. " WHERE seqData LIKE '%".$locusId."%'");
    return () if @relCarts==0;
    @relCarts = resourceListRead($userId,'cart',@relCarts);
    return () if @relCarts == 0;

    my @carts = Bio::KBase::ProteinInfoService::Browser::DB::dbSqlResults("SELECT cartId,seqData FROM genomics_test.Carts"
					  . " WHERE cartId IN (".join(",",@relCarts).")"
					  . " order by cartId");
    @relCarts = ();
    foreach my $cart (@carts) {
	my @loci = split /,/,$cart->{seqData};
	foreach my $cartlocus (@loci) {
	    if ($cartlocus eq $locusId) {
		push @relCarts, $cart->{cartId};
		next;
	    }
	}
    }
    return @relCarts;
}

1;
