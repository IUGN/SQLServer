SELECT [name], [log_reuse_wait_desc] FROM sys.databases ORDER BY [name] 


DBCC SQLPERF ('LOGSPACE') 
GO


with dm_exec_Long_tran ( 
[now], 
session_id,  
[Login Name], 
[program_name],  
[host_name], 
[Database],  
[Begin Time],  
[Duration minute], 
ax_session, 
ax_user, 
[Transaction State],  
[Last Transaction Text],  
[Last Query Plan], 
status 
) 
as ( 
  SELECT  
GETDATE() as now, 
DTST.[session_id],  
DES.[login_name] AS [Login Name], 
DES.program_name AS  [program_name],  
DES.host_name AS [host_name], 
DB_NAME (DTDT.database_id)  AS [Database],  
DTDT.[database_transaction_begin_time] AS [Begin Time],  
DATEDIFF(MINUTE,DTDT.[database_transaction_begin_time],  GETDATE()) AS [Duration minute], 
      cast(substring(ltrim(cast(DES.context_info as varchar(128))), 
      patindex('% %', ltrim(cast(DES.context_info as varchar(128)))) + 1, 
      patindex('% %', substring(ltrim(cast(DES.context_info as varchar(128))), 
      patindex('% %', ltrim(cast(DES.context_info as varchar(128)))) + 1, 
      len(cast(DES.context_info as varchar(128))))) - 1) as int) as ax_session, 
    substring(cast(DES.context_info as varchar(128)), 2, patindex('% %', 
      ltrim(cast(DES.context_info as varchar(128))))) as ax_user, 
   CASE DTAT.transaction_state  
    WHEN 0  THEN 'Not fully initialized'   
     WHEN 1  THEN  'Initialized, not started'  
     WHEN 2  THEN  'Active'  
     WHEN 3  THEN  'Ended'   
     WHEN 4  THEN  'Commit initiated'   
     WHEN 5  THEN  'Prepared, awaiting resolution'  
     WHEN 6  THEN  'Committed'  
     WHEN 7  THEN  'Rolling back'  
     WHEN 8  THEN  'Rolled back'  
   END AS [Transaction State],  
DEST.[text] AS [Last Transaction Text],  
DEQP.[query_plan] AS [Last Query Plan],  
DES.status 
FROM sys.dm_tran_database_transactions DTDT   
INNER JOIN sys.dm_tran_session_transactions DTST   
   ON DTST.[transaction_id] = DTDT.[transaction_id]  
INNER JOIN sys.[dm_tran_active_transactions] DTAT   
   ON DTST.[transaction_id] = DTAT.[transaction_id]  
INNER JOIN sys.[dm_exec_sessions] DES  
    ON DES.[session_id]  = DTST.[session_id]   
INNER JOIN sys.dm_exec_connections DEC   
   ON DEC.[session_id]  = DTST.[session_id]   
LEFT  JOIN sys.dm_exec_requests DER  
    ON DER.[session_id]  = DTST.[session_id]   
CROSS APPLY sys.dm_exec_sql_text  (DEC.[most_recent_sql_handle])  AS DEST  
OUTER APPLY sys.dm_exec_query_plan  (DER.[plan_handle])  AS DEQP  
WHERE  
  cast(DES.context_info as varchar(128)) > '' 
    and  substring(cast(DES.context_info as varchar(128)), 1, 1) = ' ' 
AND  
DATEDIFF(MINUTE,DTDT.[database_transaction_begin_time],  GETDATE()) > 60 
) 
--INSERT INTO [Management].[dbo].[LongTransactions] 
select  
LTR.[now], 
LTR.session_id,  
LTR.[Login Name],  
LTR.[Database],  
LTR.[Begin Time],  
LTR.[Duration minute], 
LTR.ax_session, 
LTR.ax_user, 
LTR.[host_name], 
LTR.[program_name], 
LTR.status, 
LTR.[Transaction State],  
LTR.[Last Transaction Text],  
LTR.[Last Query Plan],  
  b.caption as batch_caption, 
  cit.name as batch_class 
from dm_exec_Long_tran as LTR 
join userinfo as ui 
  on ui.id = LTR.ax_user 
left join batch as b 
  on b.sessionidx = LTR.ax_session and b.status = 2 
left join classidtable as cit 
  on cit.id = b.classnumber 
ORDER BY [Duration minute]  DESC;



SELECT count (*) 
FROM sys.dm_exec_requests 
WHERE blocking_session_id  <> 0 and database_id = DB_ID ('Logist') 
go



--Определение запросов ожидающих чтение с диска. 

SELECT 'Waiting_tasks' AS [Information], owt.session_id, 
    owt.wait_duration_ms, owt.wait_type, owt.blocking_session_id, 
    owt.resource_description, es.program_name, est.text, 
    est.dbid, eqp.query_plan, er.database_id, es.cpu_time, 
    es.memory_usage*8 AS memory_usage_KB 
FROM sys.dm_os_waiting_tasks owt 
INNER JOIN sys.dm_exec_sessions es ON owt.session_id = es.session_id 
INNER JOIN sys.dm_exec_requests er ON es.session_id = er.session_id 
OUTER APPLY sys.dm_exec_sql_text (er.sql_handle) est 
OUTER APPLY sys.dm_exec_query_plan (er.plan_handle) eqp 
WHERE es.is_user_process = 1 
ORDER BY owt.session_id; 
GO 

--Выявление запросов с высоким количеством физического чтения с диска 

select top 10 QS.*, SP.query_plan 
FROM sys.dm_exec_query_stats QS 
CROSS APPLY sys.dm_exec_query_plan (QS.plan_handle) as SP 
order by total_physical_reads desc 

--Запросы, которые запросили и ожидают предоставления памяти или получили выделение памяти. 
--Active requests with memory grants 
SELECT 
--Session data  
  s.[session_id], s.open_transaction_count 
--Memory usage 
, r.granted_query_memory, mg.grant_time, mg.requested_memory_kb, mg.granted_memory_kb, mg.required_memory_kb, mg.used_memory_kb, mg.max_used_memory_kb      
--Query  
, query_text = t.text, input_buffer = ib.event_info, query_plan_xml = qp.query_plan, request_row_count = r.row_count, session_row_count = s.row_count 
--Session history and status 
, s.last_request_start_time, s.last_request_end_time, s.reads, s.writes, s.logical_reads, session_status = s.[status], request_status = r.status 
--Session connection information 
, s.host_name, s.program_name, s.login_name, s.client_interface_name, s.is_user_process 
FROM sys.dm_exec_sessions s  
LEFT OUTER JOIN sys.dm_exec_requests AS r  
    ON r.[session_id] = s.[session_id] 
LEFT OUTER JOIN sys.dm_exec_query_memory_grants AS mg  
    ON mg.[session_id] = s.[session_id] 
OUTER APPLY sys.dm_exec_sql_text (r.[sql_handle]) AS t 
OUTER APPLY sys.dm_exec_input_buffer(s.[session_id], NULL) AS ib  
OUTER APPLY sys.dm_exec_query_plan (r.[plan_handle]) AS qp  
WHERE mg.granted_memory_kb > 0 
ORDER BY mg.granted_memory_kb desc, mg.requested_memory_kb desc; 
GO 

/*Два запроса не написал, я от них отказался, потому что, лучше использовать мониторинг Zabbix для выявления сбросов PLE во времени. 
https://zbx.goldapple.ru/history.php?action=showgraph&itemids[]=967580
*/

SELECT OBJECT_NAME(stat.object_id) AS object_name, sp.stats_id, name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter    
FROM sys.stats AS stat    
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp   
ORDER BY 5 desc
