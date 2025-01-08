WITH
    threads
    AS
    (
        SELECT TOP (10)
            deqs.sql_handle,
            deqs.plan_handle,
            deqs.total_reserved_threads,
            deqs.last_reserved_threads,
            deqs.min_reserved_threads,
            deqs.max_reserved_threads,
            deqs.total_used_threads,
            deqs.last_used_threads,
            deqs.min_used_threads,
            deqs.max_used_threads,
            deqs.execution_count
        FROM sys.dm_exec_query_stats AS deqs
        WHERE deqs.min_reserved_threads > 0
        ORDER BY deqs.max_reserved_threads DESC
    )
SELECT t.execution_count,
    t.total_reserved_threads,
    t.last_reserved_threads,
    t.min_reserved_threads,
    t.max_reserved_threads,
    t.total_used_threads,
    t.last_used_threads,
    t.min_used_threads,
    t.max_used_threads,
    CASE WHEN (t.min_reserved_threads * 2) < t.max_reserved_threads 
THEN 'maybe'
ELSE 'maybe not'
END AS [sniffy?],
    d.query_plan
FROM threads AS t
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS d
ORDER BY t.execution_count DESC, t.max_used_threads DESC
