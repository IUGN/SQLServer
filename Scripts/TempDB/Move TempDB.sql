USE TempDB
GO
EXEC sp_helpfile
GO

--Источник <https://blog.sqlauthority.com/2016/06/26/moving-tempdb-new-drive-interview-question-week-077/> 


USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'd:\datatempdb.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'e:\datatemplog.ldf')
GO

--Источник <https://blog.sqlauthority.com/2016/06/26/moving-tempdb-new-drive-interview-question-week-077/> 


SELECT 'ALTER DATABASE tempdb MODIFY FILE (NAME = [' + f.name + '],'
	+ ' FILENAME = ''Z:\MSSQL\DATA\' + f.name
	+ CASE WHEN f.type = 1 THEN '.ldf' ELSE '.mdf' END
	+ ''');'
FROM sys.master_files f
WHERE f.database_id = DB_ID(N'tempdb');

--https://www.brentozar.com/archive/2017/11/move-tempdb-another-drive-folder/
