SELECT r.plan_handle, t.*, qp.*
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp
WHERE session_id = 294



DBCC FREEPROCCACHE (0x0600050049A06832B09D97A29602000001000000000000000000000000000000000000000000000000000000);