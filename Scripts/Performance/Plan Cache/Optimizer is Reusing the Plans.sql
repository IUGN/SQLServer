SELECT eqs.query_hash AS QueryHash
 ,COUNT(DISTINCT sql_handle) AS CountOfSQLHandles
 ,SUM(execution_count) AS NoOfExecutions 
,SUM(eqs.total_logical_reads) AS TotalLogicalReads 
,SUM(eqs.total_worker_time) AS TotalCPUTime 
,SUM(eqs.total_elapsed_time) AS TotalDuration 
,MAX(est.[TEXT]) AS OneSuchQuery 
FROM sys.dm_exec_query_stats eqs
CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) est
GROUP BY eqs.query_hash
-- HAVING COUNT(DISTINCT sql_handle) > 2
-- Adding HAVING clause will help us to concentrate frequently executing queries
-- You can play with the number in the HAVING filter as per your requirement