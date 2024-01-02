USE tempdb
GO

SELECT
SUM(unallocated_extent_page_count) AS [free pages],
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB],
(SUM(allocated_extent_page_count)*1.0/128) AS [used space in MB]
FROM sys.dm_db_file_space_usage;

Источник <https://its.1c.ru/db/content/metod8dev/src/developers/scalability/troubleshooting/i8105900.htm