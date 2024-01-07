SELECT
 ag.name AS AvailabilityGroup,
 ar.replica_server_name AS ReplicaName,
 d.name AS DatabaseName,
 drs.database_state_desc,
 drs.synchronization_state_desc,
 drs.synchronization_health_desc
 FROM
 sys.availability_groups ag join sys.availability_replicas ar
 on ag.group_id=ar.group_id
 join sys.dm_hadr_database_replica_states drs
 on ar.replica_id=drs.replica_id
 join sys.databases d
 on d.database_id=drs.database_id

/*
The synchronization_health_desc column can have the following values:
 •  HEALTHY : This is when the synchronization state is either SYNCHRONIZED or SYNCHRONIZING.
 •  NOT_HEALTHY : This is when the synchronization state is NOT SYNCHRONIZING.
 •  PARTIALLY_HEALTHY : This is when the synchronization state of a synchronous replica is SYNCHRONIZING. 
 This can happen during initialization, role switch, or in case of slow network connectivity.
*/
