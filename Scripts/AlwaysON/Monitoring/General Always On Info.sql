SELECT ar.replica_server_name, 
       adc.database_name, 
       ag.name ASag_name, 
       drs.is_local, 
       drs.synchronization_state_desc, 
       drs.synchronization_health_desc, 
       drs.last_redone_time, 
       drs.redo_queue_size, 
       drs.redo_rate, 
       (drs.redo_queue_size /drs.redo_rate) /60.0 AS est_redo_completion_time_min,
       drs.last_commit_lsn, 
       drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
       ON drs.group_id =adc.group_id AND drs.group_database_id =adc.group_database_id
INNER JOIN sys.availability_groups AS ag
       ON ag.group_id =drs.group_id
INNER JOIN sys.availability_replicas AS ar 
       ON drs.group_id =ar.group_id AND drs.replica_id =ar.replica_id
ORDER BY ag.name, 
       ar.replica_server_name, 
       adc.database_name;
      

--Источник <https://dba.stackexchange.com/questions/253619/whats-the-cause-for-an-alwayson-ag-secondary-replica-to-have-a-high-redo-queue> 


SELECT ar.replica_server_name, 
       adc.database_name, 
       ag.name ASag_name, 
       drs.is_local, 
       drs.synchronization_state_desc, 
       drs.synchronization_health_desc, 
       drs.last_redone_time, 
       drs.redo_queue_size, 
       drs.redo_rate, 
       (drs.redo_queue_size /drs.redo_rate) /60.0 AS est_redo_completion_time_min,
       drs.last_commit_lsn, 
       drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
       ON drs.group_id =adc.group_id AND drs.group_database_id =adc.group_database_id
INNER JOIN sys.availability_groups AS ag
       ON ag.group_id =drs.group_id
INNER JOIN sys.availability_replicas AS ar 
       ON drs.group_id =ar.group_id AND drs.replica_id =ar.replica_id
ORDER BY ag.name, 
       ar.replica_server_name, 
       adc.database_name;

