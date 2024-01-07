/*Типичный сценарий отладки для времени ожидания запроса может исследовать следующее:
	• Проверьте общее состояние системной памяти с помощью представлений sys.dm_os_memory_clerks, sys.dm_os_sys_info и различных счетчиков производительности.
	• Проверьте наличие резервирований памяти для выполнения запросов в sys.dm_os_memory_clerks , где type = 'MEMORYCLERK_SQLQERESERVATIONS'.
	• Проверьте запросы, ожидающие 1 для получения разрешений, с помощью sys.dm_exec_query_memory_grants:
*/
--Find all queries waiting in the memory queue  
SELECT * FROM sys.dm_exec_query_memory_grants WHERE grant_time IS NULL;

/*В этом случае типом ожидания, как правило, является RESOURCE_SEMAPHORE. Для получения дополнительной информации см. sys.dm_os_wait_stats (Transact-SQL).
	• Кэш поиска запросов с выделением памяти с помощью sys.dm_exec_cached_plans (Transact-SQL) и sys.dm_exec_query_plan (Transact-SQL)
*/

-- retrieve every query plan from the plan cache  
USE master;  
GO  
SELECT * 
FROM sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle);  
GO  
	/*• Если подозревается беглый запрос, изучите Showplan в столбце query_planиз sys.dm_exec_query_plan и пакет text запроса из sys.dm_exec_sql_text. 
    Дополнительные сведения о том, как в настоящее время выполняются запросы с большим объемом памяти, используя sys.dm_exec_requests.
*/

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

--Источник <https://learn.microsoft.com/ru-ru/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-memory-grants-transact-sql?view=sql-server-ver16> 
