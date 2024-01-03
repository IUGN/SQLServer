-- Using the sys.dm_exec_requests
SELECT session_id, blocking_session_id, open_transaction_count, wait_time, wait_type,     last_wait_type, wait_resource, transaction_isolation_level, lock_timeout
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
GO

-- Using the sys.dm_os_waiting_tasks
SELECT session_id, blocking_session_id, wait_duration_ms, wait_type, resource_description
FROM sys.dm_os_waiting_tasks
WHERE blocking_session_id IS NOT NULL


SELECT s.*
FROM sys.dm_exec_sessions AS s
WHERE EXISTS (
    SELECT *
    FROM sys.dm_tran_session_transactions AS t
    WHERE t.session_id = s.session_id
)
AND NOT EXISTS (
    SELECT *
    FROM sys.dm_exec_requests AS r
    WHERE r.session_id = s.session_id
);

