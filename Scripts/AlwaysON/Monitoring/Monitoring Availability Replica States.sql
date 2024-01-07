SELECT
 ag.name AS AvailabilityGroup,
 ar.replica_server_name AS ReplicaName,
 ars.role_desc AS Role,
 ars.operational_state_desc
 FROM
 sys.availability_groups ag join sys.availability_replicas ar
 on ag.group_id=ar.group_id
 join sys.dm_hadr_availability_replica_states ars
 on ar.replica_id=ars.replica_id

/*
The Role column returns the current availability role of the replica. It can have any one of the following three values: PRIMARY , SECONDARY , and RESOLVING . The RESOLVING value is usually used when a replica is in a transient state from primary to secondary or vice versa.
 The operational_state_desc column can have following values:
 •  PENDING_FAILOVER : This is when the failover is being performed for an availability group.
 •  OFFLINE : This is when there is no primary replica available in an availability group.
 •  ONLINE : This is when the replica is online.
 •  FAILED : This is when the replica can't read or write from the WSFC cluster.
 •  NULL : This is when the replica is a remote replica.
 */