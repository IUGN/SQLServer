/*Индексы имеют свои издержки на обслуживание. Это и занимаемое место, и увеличение времени записи, 
а также потребность их реорганизации / ребилда после некоторого периода использования. 
Поэтому было бы не плохо понять какие индексы по-настоящему нужны. 
Для этого и нужна статистика использования индексов.*/
 
SELECT OBJECT_NAME(IX.OBJECT_ID) Table_Name
       ,IX.name AS Index_Name
       ,IX.type_desc Index_Type
       ,SUM(PS.[used_page_count]) * 8 IndexSizeKB
       ,IXUS.user_seeks AS NumOfSeeks
       ,IXUS.user_scans AS NumOfScans
       ,IXUS.user_lookups AS NumOfLookups
       ,IXUS.user_updates AS NumOfUpdates
       ,IXUS.last_user_seek AS LastSeek
       ,IXUS.last_user_scan AS LastScan
       ,IXUS.last_user_lookup AS LastLookup
       ,IXUS.last_user_update AS LastUpdate
FROM sys.indexes IX
INNER JOIN sys.dm_db_index_usage_stats IXUS ON IXUS.index_id = IX.index_id AND IXUS.OBJECT_ID = IX.OBJECT_ID
INNER JOIN sys.dm_db_partition_stats PS on PS.object_id=IX.object_id
WHERE OBJECTPROPERTY(IX.OBJECT_ID,'IsUserTable') = 1
GROUP BY OBJECT_NAME(IX.OBJECT_ID) ,IX.name ,IX.type_desc ,IXUS.user_seeks ,IXUS.user_scans ,IXUS.user_lookups,IXUS.user_updates ,IXUS.last_user_seek ,IXUS.last_user_scan ,IXUS.last_user_lookup ,IXUS.last_user_update

/* Этим скриптом Вы можете получить информацию о количестве операций поиска, сканирования и некоторых других операций на индексах. В итоге можно составить список тех объектов, которых из базы можно удалить.
 
Для платформы 1С удаление неиспользуемых индексов штатными средствами не всегда возможно. Но если сильно захотеть...
 
Кроме этого, можно составить список индексов, которые имеют высокие издержки при использовании. Возможно, это "тяжелые" индексы, которые созданы на часто обновляемых таблицах или др. варианты.
*/ 
SELECT TOP 1
    [Maintenance cost]  = (user_updates + system_updates)
       , [Retrieval usage] = (user_seeks + user_scans + user_lookups)
       , DatabaseName = DB_NAME()
       , TableName = OBJECT_NAME(s.[object_id])
       , IndexName = i.name
INTO #TempMaintenanceCost
FROM sys.dm_db_index_usage_stats s
    INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id]
        AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND (user_updates + system_updates) &gt; 0 -- Only report on active rows.
    AND s.[object_id] = -999
-- Dummy value to get table structure.
;
 
-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    'USE [?];
-- Table already exists.
INSERT INTO #TempMaintenanceCost
SELECT TOP 10
       [Maintenance cost]  = (user_updates + system_updates)
       ,[Retrieval usage] = (user_seeks + user_scans + user_lookups)
       ,DatabaseName = DB_NAME()
       ,TableName = OBJECT_NAME(s.[object_id])
       ,IndexName = i.name
FROM   sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id]
   AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
   AND i.name IS NOT NULL    -- Ignore HEAP indexes.
   AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
   AND (user_updates + system_updates) &gt; 0 -- Only report on active rows.
ORDER BY [Maintenance cost]  DESC
;
'
-- Select records.
SELECT TOP 10
    *
FROM #TempMaintenanceCost
ORDER BY [Maintenance cost]  DESC
-- Tidy up.
DROP TABLE #TempMaintenanceCost

--Источник <https://bookflow.ru/nabor-skriptov-sql-server-dlya-sistemnogo-administratora/> 


SELECT TableName = sc.name + ‘.’ + o.name, IndexName = i.name
     , s.user_seeks, s.user_scans, s.user_lookups
     , s.user_updates
     , ps.row_count, SizeMb = (ps.in_row_reserved_page_count*8.)/1024.
     , s.last_user_lookup, s.last_user_scan, s.last_user_seek
     , s.last_user_update
FROM sys.dm_db_index_usage_stats AS s
  INNER JOIN sys.indexes AS i 
ON i.object_id = s.object_id AND i.index_id = s.index_id
   INNER JOIN sys.objects AS o ON o.object_id=i.object_id
   INNER JOIN sys.schemas AS sc ON sc.schema_id = o.schema_id
    INNER JOIN sys.partitions AS pr
ON pr.object_id = i.object_id AND pr.index_id = i.index_id
    INNER JOIN sys.dm_db_partition_stats AS ps
ON ps.object_id = i.object_id AND ps.partition_id = pr.partition_id
WHERE o.is_ms_shipped = 0
--Don’t consider dropping any constraints 
AND i.is_unique = 0 AND i.is_primary_key = 0 AND i.is_unique_constraint = 0
--Order by table reads asc, table writes desc
ORDER BY user_seeks + user_scans + user_lookups asc, s.user_updates desc;
 

--from book
