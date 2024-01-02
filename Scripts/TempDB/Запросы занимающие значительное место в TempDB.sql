SELECT r.session_id, r.request_id, t.text AS query,
    u.allocated AS task_internal_object_page_allocation_count,
    u.deallocated AS task_internal_object_page_deallocation_count
FROM (
    SELECT session_id, request_id,
        SUM(internal_objects_alloc_page_count) AS allocated,
        SUM (internal_objects_dealloc_page_count) AS deallocated
    FROM sys.dm_db_task_space_usage
    GROUP BY session_id, request_id) AS u
JOIN sys.dm_exec_requests AS r
ON u.session_id = r.session_id  AND u.request_id = r.request_id
CROSS APPLY sys.dm_exec_sql_text (r.sql_handle) as t
ORDER BY u.allocated DESC;



SELECT r.session_id, r.request_id, r.total_elapsed_time, t.text AS query, 
    u.allocated AS task_internal_object_page_allocation_count,
    u.deallocated AS task_internal_object_page_deallocation_count
FROM (
    SELECT session_id, request_id,
        SUM(internal_objects_alloc_page_count) AS allocated,
        SUM (internal_objects_dealloc_page_count) AS deallocated
    FROM sys.dm_db_task_space_usage
    GROUP BY session_id, request_id) AS u
JOIN sys.dm_exec_requests AS r
ON u.session_id = r.session_id  AND u.request_id = r.request_id
CROSS APPLY sys.dm_exec_sql_text (r.sql_handle) as t
ORDER BY u.allocated DESC;
