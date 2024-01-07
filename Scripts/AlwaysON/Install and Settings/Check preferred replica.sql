IF (sys.fn_hadr_backup_is_preferred_replica('Sales') = 1)
-- BEGIN
 --SELECT @@SERVERNAME AS 'Preferred Replica'
 --BACKUP DATABASE Sales TO DISK = '\\DPLPR\Backup\Sales.bak' WITH COPY_ONLY
 --END
