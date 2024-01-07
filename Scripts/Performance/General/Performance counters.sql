select *
FROM sys.dm_os_performance_counters
where counter_name ='Longest Transaction Running Time'