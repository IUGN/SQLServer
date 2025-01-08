select a.DBName, max(a.backup_finish_date) as date, 'D' as type
from (SELECT d.Name AS DBName ,
                b.Backup_finish_date ,
                b.type,
                bmf.Physical_Device_name
        FROM sys.databases d
                INNER JOIN msdb..backupset b ON b.database_name = d.name
                        AND b.[type] = 'D'
                INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id) as a
group by a.DBName
order by date desc



select a.DBName, max(a.backup_finish_date) as date, 'I' as type
from (SELECT d.Name AS DBName ,
                b.Backup_finish_date ,
                b.type,
                bmf.Physical_Device_name
        FROM sys.databases d
                INNER JOIN msdb..backupset b ON b.database_name = d.name
                        AND b.[type] = 'I'
                INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id) as a
group by a.DBName
order by date desc

