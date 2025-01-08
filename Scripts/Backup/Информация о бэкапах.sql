SELECT @@Servername AS ServerName ,
        d.Name AS DBName ,
        MAX(b.backup_finish_date) AS LastBackupCompleted
FROM sys.databases d
        LEFT OUTER JOIN msdb..backupset b
        ON b.database_name = d.name
                AND b.[type] = 'D'
GROUP BY d.Name
ORDER BY d.Name;
--Источник <https://bookflow.ru/nabor-skriptov-sql-server-dlya-sistemnogo-administratora/> 
