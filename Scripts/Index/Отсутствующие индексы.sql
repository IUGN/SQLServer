/* SQL Server на столько хорош, что может поделиться информацией об отсутствующих индексах, 
наличие которых бы смогло повысить эффективность работы запросов. */
 
SELECT 
    @@ServerName AS ServerName, -- Имя сервера
    DB_NAME() AS DBName, -- Имя базы
    t.name AS 'Affected_table', -- Имя таблицы
    (LEN(ISNULL(ddmid.equality_columns, N'')
              + CASE WHEN ddmid.equality_columns IS NOT NULL
    AND ddmid.inequality_columns IS NOT NULL THEN ','
                     ELSE ''
                END) - LEN(REPLACE(ISNULL(ddmid.equality_columns, N'')
                                   + CASE WHEN ddmid.equality_columns
                                                             IS NOT NULL
    AND ddmid.inequality_columns
                                                             IS NOT NULL
                                          THEN ','
                                          ELSE ''
                                     END, ',', '')) ) + 1 AS K, -- Количество ключей в индексе
  COALESCE(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + COALESCE(ddmid.inequality_columns, '') AS Keys, -- Ключевые столбцы индекса
  COALESCE(ddmid.included_columns, '') AS [include], -- Неключевые столбцы индекса
  'Create NonClustered Index IX_' + t.name + '_missing_'
        + CAST(ddmid.index_handle AS VARCHAR(20)) 
        + ' On ' + ddmid.[statement] COLLATE database_default
        + ' (' + ISNULL(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + ISNULL(ddmid.inequality_columns, '') + ')'
        + ISNULL(' Include (' + ddmid.included_columns + ');', ';')
                                                  AS sql_statement, -- Команда для создания индекса
  ddmigs.user_seeks, -- Количество операций поиска
  ddmigs.user_scans, -- Количество операций сканирования
  CAST(( ddmigs.user_seeks + ddmigs.user_scans)
        * ddmigs.avg_user_impact AS BIGINT) AS 'est_impact', 
  avg_user_impact, -- Средний процент выигрыша
  ddmigs.last_user_seek, -- Последняя операция поиска
  ( SELECT DATEDIFF(Second, create_date, GETDATE()) Seconds
  FROM sys.databases
  WHERE     name = 'tempdb'
        ) SecondsUptime
FROM sys.dm_db_missing_index_groups ddmig
  INNER JOIN sys.dm_db_missing_index_group_stats ddmigs
  ON ddmigs.group_handle = ddmig.index_group_handle
  INNER JOIN sys.dm_db_missing_index_details ddmid
  ON ddmig.index_handle = ddmid.index_handle
  INNER JOIN sys.tables t ON ddmid.OBJECT_ID = t.OBJECT_ID
WHERE   ddmid.database_id = DB_ID()
ORDER BY est_impact DESC;

--Источник <https://bookflow.ru/nabor-skriptov-sql-server-dlya-sistemnogo-administratora/> 



SELECT mid.[statement], create_index_statement =
     CONCAT('CREATE NONCLUSTERED INDEX IDX_NC_', 
      TRANSLATE(replace(mid.equality_columns, ' ' ,''), '],[' ,'___')
    , TRANSLATE(replace(mid.inequality_columns, ' ' ,''), '],[' ,'___')
    , ' ON ' , mid.[statement] , ' (' , mid.equality_columns
    , CASE WHEN mid.equality_columns IS NOT NULL
     AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
    , mid.inequality_columns , ')'
    , ' INCLUDE (' , mid.included_columns , ')' )
, migs.unique_compiles, migs.user_seeks, migs.user_scans
, migs.last_user_seek, migs.avg_total_user_cost
, migs.avg_user_impact, mid.equality_columns
, mid.inequality_columns, mid.included_columns
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid
ON mig.index_handle = mid.index_handle
INNER JOIN sys.tables t ON t.object_id = mid.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE mid.database_id = DB_ID()  
-- count of query compilations that needed this proposed index
--AND       migs.unique_compiles > 10
-- count of query seeks that needed this proposed index
--AND       migs.user_seeks > 10
-- average percentage of cost that could be alleviated with this proposed index
--AND       migs.avg_user_impact > 75
-- Sort by indexes that will have the most impact to the costliest queries
ORDER BY migs.avg_user_impact * migs.avg_total_user_cost desc;

--From book
