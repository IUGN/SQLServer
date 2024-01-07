/*Чем выше процент фрагментации индекса в базе, тем меньше его эффективность. 
Почему? Все просто - части индекса разбросаны по файлу базы данных и для использования 
индекса все эти части нужно собрать. Чем больше фрагментация, тем сложнее это сделать. 
В случаях, когда процент фрагментации большой, СУБД может вообще отказаться от использования такого индекса. */
 
SELECT
    DB_NAME([IF].database_id) AS [Имя базы] 
    ,OBJECT_NAME(object_id) AS [Имя таблицы] 
    ,OBJECT_NAME([IF].index_id) AS [Имя индкса] 
    ,[IF].*
FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) AS [IF]
WHERE avg_fragmentation_in_percent > 30
ORDER BY avg_fragmentation_in_percent

--Источник <https://bookflow.ru/nabor-skriptov-sql-server-dlya-sistemnogo-administratora/> 
