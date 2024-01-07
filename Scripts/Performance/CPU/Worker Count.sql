SELECT max_workers_count
FROM sys.dm_os_sys_info

--Источник <https://blog.sqlauthority.com/2018/06/15/sql-server-optimal-value-max-worker-threads/> 
/*
For x86 (32-bit) upto 4 logical processors  max worker threads = 256
For x86 (32-bit) more than 4 logical processors  max worker threads = 256 + ((# Procs – 4) * 8)
For x64 (64-bit) upto 4 logical processors  max worker threads = 512
For x64 (64-bit) more than 4 logical processors  max worker threads = 512+ ((# Procs – 4) * 16)
*/
--Источник <https://blog.sqlauthority.com/2010/04/20/sql-server-find-max-worker-count-using-dmv-32-bit-and-64-bit/> 


SELECT COUNT(*)AS worker_count
FROM sys.dm_os_workers AS w
INNER JOIN sys.dm_os_tasks AS t ON
   w.task_address = t.task_address
WHERE t.session_id = 56;

--Источник <https://www.sqlservercentral.com/articles/sql-server-2012%E2%80%99s-information-on-parallel-thread-usage> 

