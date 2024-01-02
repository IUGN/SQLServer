SELECT  
DatabaseName = x.database_name,
        LastBackupFileName = x.physical_device_name,
		DirectoryPath = LEFT (x.physical_device_name, LEN(x.physical_device_name) - (CHARINDEX('\', REVERSE(x.physical_device_name), 1)) + 1),
       LastBackupDatetime = x.backup_start_date
FROM (  SELECT  bs.database_name,
                bs.backup_start_date,
                bmf.physical_device_name,
                  Ordinal = ROW_NUMBER() OVER( PARTITION BY bs.database_name ORDER BY bs.backup_start_date DESC )
          FROM  msdb.dbo.backupmediafamily bmf
                  JOIN msdb.dbo.backupmediaset bms ON bmf.media_set_id = bms.media_set_id
                  JOIN msdb.dbo.backupset bs ON bms.media_set_id = bs.media_set_id
          WHERE   bs.[type] = 'D'
                  AND bs.is_copy_only = 0 ) x
WHERE x.Ordinal = 1
ORDER BY DatabaseName;
