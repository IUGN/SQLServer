DECLARE @DBNAME nvarchar(20)
set @DBNAME = 'AXDB'
IF (sys.fn_hadr_backup_is_preferred_replica(@DBNAME) != 1)  
BEGIN  
   RAISERROR (N'Not Primary replica.',
    16, -- Severity,  
    1)
END 