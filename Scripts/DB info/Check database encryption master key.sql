DECLARE @command varchar(1000)
SELECT @command = '
PRINT ''?'';
IF EXISTS(SELECT 1 FROM [?].sys.symmetric_keys)
BEGIN
  USE [?];
  PRINT '' Key(s) found!'';
  SELECT ''?'' AS db_name, *
  FROM sys.symmetric_keys
END
'

EXEC sp_MSforeachdb @command
