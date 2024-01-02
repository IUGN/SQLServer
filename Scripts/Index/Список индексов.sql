--Составим список таблиц и их индексов.
 
SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.Name AS TableName ,
        i.Name AS IndexName
FROM    sys.objects o
        INNER JOIN sys.indexes i ON o.object_id = i.object_id
WHERE   o.Type = 'U' -- User table 
        AND LEFT(i.Name, 1) &lt;&gt; '_' -- Remove hypothetical indexes 
ORDER BY o.NAME ,
        i.name;

--Источник <https://bookflow.ru/nabor-skriptov-sql-server-dlya-sistemnogo-administratora/> 
