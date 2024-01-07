SELECT
    PlanUse = CASE WHEN p.usecounts > 1 THEN '>1' ELSE '1' END
    , PlanCount = COUNT(1)
     , SizeInMB = SUM(p.size_in_bytes/1024./1024.)
FROM sys.dm_exec_cached_plans p
GROUP BY CASE WHEN p.usecounts > 1 THEN '>1' ELSE '1' END;