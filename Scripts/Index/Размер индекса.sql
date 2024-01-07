SELECT i.[name] AS IndexName
    ,SUM(s.[used_page_count]) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats AS s
INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
    AND s.[index_id] = i.[index_id]
where i.name ='I_4022TABLERECIDIDX'
GROUP BY i.[name]
ORDER BY i.[name]



SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.Name AS TableName ,
        i.Name AS IndexName
FROM    sys.objects o
        INNER JOIN sys.indexes i ON o.object_id = i.object_id
WHERE   o.Type = 'U' -- User table 
        AND LEFT(i.Name, 1) <> '_'
		AND o.Name='sysdatabaselog'

