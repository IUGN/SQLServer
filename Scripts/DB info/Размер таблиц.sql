CREATE TABLE #Results(
  [Name] nvarchar(128),
  [Rows] char(11),
  ReservedKB varchar(18),
  DataKB varchar(18),
  Index_sizeKB varchar(18),
  UnusedKB varchar(18))
GO
INSERT INTO #Results
exec sp_msforeachtable @command1 = N'exec sp_spaceused ''?'', false'

SELECT [Name], [rows], REPLACE(ReservedKB, ' KB', '') as ReservedKB, REPLACE(DataKB, ' KB', '') as DataKB,
    REPLACE(Index_sizeKB, ' KB', '') as Index_sizeKB, REPLACE(UnusedKB, ' KB', '') as UnusedKB FROM #Results
ORDER BY [NAME]
GO

DROP TABLE #Results
GO




Количество записей - это хорошо. Но узнать размер хранимых данных в таблицах чаще всего более предпочтительный вариант.
 
SELECT
    a3.name AS [schemaname],
    a2.name AS [tablename],
    a1.rows as row_count,
    (a1.reserved + ISNULL(a4.reserved,0))* 8 AS [reserved], 
    a1.data * 8 AS [data],
    (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS [index_size],
    (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS [unused]
FROM
    (SELECT 
        ps.object_id,
        SUM (
            CASE
                WHEN (ps.index_id < 2) THEN row_count
                ELSE 0
            END
            ) AS [rows],
        SUM (ps.reserved_page_count) AS reserved,
        SUM (
            CASE
                WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
            END
            ) AS data,
        SUM (ps.used_page_count) AS used
    FROM sys.dm_db_partition_stats ps
    GROUP BY ps.object_id) AS a1
LEFT OUTER JOIN 
    (SELECT 
        it.parent_id,
        SUM(ps.reserved_page_count) AS reserved,
        SUM(ps.used_page_count) AS used
     FROM sys.dm_db_partition_stats ps
     INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
     WHERE it.internal_type IN (202,204)
     GROUP BY it.parent_id) AS a4 ON (a4.parent_id = a1.object_id)
INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id ) 
INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
WHERE a2.type <> N'S' and a2.type <> N'IT'
ORDER BY reserved DESC

Источник <https://bookflow.ru/nabor-skriptov-sql-server-dlya-sistemnogo-administratora/> 
