-- Контроль резервирования

select @@Servername AS ServerName, d.name, d.recovery_model_desc, fb.date as full_bckp_date, db.date as diff_bckp_date,
        lb.date as log_bckp_date, pfd.physical_device_name as full_bckp_physical_device_name
from sys.databases d
        LEFT JOIN -- Информация по полным РК
        (select a.DBName, max(a.backup_finish_date) as date, 'D' as type
        from (SELECT d.Name AS DBName ,
                        b.Backup_finish_date ,
                        b.type,
                        bmf.Physical_Device_name
                FROM sys.databases d
                        INNER JOIN msdb..backupset b ON b.database_name = d.name
                                AND b.[type] = 'D'
                        INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id) as a
        group by a.DBName) fb
        ON d.name = fb.DBName
        LEFT JOIN -- Информация по разностным РК
        (select a.DBName, max(a.backup_finish_date) as date, 'I' as type
        from (SELECT d.Name AS DBName ,
                        b.Backup_finish_date ,
                        b.type,
                        bmf.Physical_Device_name
                FROM sys.databases d
                        INNER JOIN msdb..backupset b ON b.database_name = d.name
                                AND b.[type] = 'I'
                        INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id) as a
        group by a.DBName) db
        ON d.name = db.DBName
        LEFT JOIN -- Информация по РК журнала транзакций
        (select a.DBName, max(a.backup_finish_date) as date, 'L' as type
        from (SELECT d.Name AS DBName ,
                        b.Backup_finish_date ,
                        b.type,
                        bmf.Physical_Device_name
                FROM sys.databases d
                        INNER JOIN msdb..backupset b ON b.database_name = d.name
                                AND b.[type] = 'L'
                        INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id) as a
        group by a.DBName) lb
        ON d.name = lb.DBName
        LEFT JOIN
        (SELECT d.Name AS DBName ,
                b.Backup_finish_date ,
                b.type,
                bmf.Physical_Device_name,
                round(b.backup_size/1024/1024/1024, 2) as size
        FROM sys.databases d
                INNER JOIN msdb..backupset b ON b.database_name = d.name
                        AND b.[type] = 'D'
                INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id) pfd
        ON fb.DBName = pfd.DBName AND fb.date = pfd.backup_finish_date
ORDER BY 3 desc
