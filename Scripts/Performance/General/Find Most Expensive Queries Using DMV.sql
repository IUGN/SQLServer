SELECT TOP 10 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
((CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(qt.TEXT)
ELSE qs.statement_end_offset
END - qs.statement_start_offset)/2)+1),
qs.execution_count,
qs.total_logical_reads, qs.last_logical_reads,
qs.total_logical_writes, qs.last_logical_writes,
qs.total_worker_time,
qs.last_worker_time,
qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
qs.last_execution_time,
qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_logical_reads DESC -- logical reads
-- ORDER BY qs.total_logical_writes DESC -- logical writes
-- ORDER BY qs.total_worker_time DESC -- CPU time

--Источник <https://blog.sqlauthority.com/2010/05/14/sql-server-find-most-expensive-queries-using-dmv/> 

SELECT TOP(50) qs.execution_count AS [Execution Count],
(qs.total_logical_reads)*8/1024.0 AS [Total Logical Reads (MB)],
(qs.total_logical_reads/qs.execution_count)*8/1024.0 AS [Avg Logical Reads (MB)],
(qs.total_worker_time)/1000.0 AS [Total Worker Time (ms)],
(qs.total_worker_time/qs.execution_count)/1000.0 AS [Avg Worker Time (ms)],
(qs.total_elapsed_time)/1000.0 AS [Total Elapsed Time (ms)],
(qs.total_elapsed_time/qs.execution_count)/1000.0 AS [Avg Elapsed Time (ms)],
qs.creation_time AS [Creation Time]
,t.text AS [Complete Query Text], qp.query_plan AS [Query Plan]
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE t.dbid = DB_ID()
ORDER BY qs.execution_count DESC OPTION (RECOMPILE);-- frequently ran query
-- ORDER BY [Total Logical Reads (MB)] DESC OPTION (RECOMPILE);-- High Disk Reading query
-- ORDER BY [Avg Worker Time (ms)] DESC OPTION (RECOMPILE);-- High CPU query
-- ORDER BY [Avg Elapsed Time (ms)] DESC OPTION (RECOMPILE);-- Long Running query

--Источник <https://blog.sqlauthority.com/2021/03/17/sql-server-list-expensive-queries-updated-march-2021/> 


