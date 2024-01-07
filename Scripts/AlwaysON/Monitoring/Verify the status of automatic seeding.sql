	SELECT
	 has.start_time
	 ,has.completion_time
	 ,ags.name
	 ,db.database_name
	 ,has.current_state
	 ,has.performed_seeding
	 ,has.failure_state
	 ,has.failure_state_desc
	 FROM sys.dm_hadr_automatic_seeding as has
	 JOIN sys.availability_databases_cluster as db
	 ON has.ag_db_id = db.group_database_id
	 JOIN sys.availability_groups as ags
 ON has.ag_id = ags.group_id