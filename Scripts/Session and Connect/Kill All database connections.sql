/*
DESCRIPTION:
This script will terminate all connections to a database, usefull when you have to schedule a restore on test environemnt.

INPUT PARAMETERS: 
Database Name 

HOW TO USE: 
You can include this script as at the begining of the restore statement, so that all the connections to a database get terminated before
actual restore starts.
*/
USE master
Go

DECLARE @dbid INT , @spid INT , @STR NVARCHAR(500)
--Replace dbname with your database name 
SET @dbid = DB_ID('dbname')
  
DECLARE rs SCROLL CURSOR FOR     
SELECT spid FROM sysprocesses WHERE dbid = @dbid    
OPEN rs    
FETCH FIRST FROM rs INTO @spid     
	WHILE @@fetch_status= 0    
	BEGIN    
		SELECT @STR = 'KILL '  + CONVERT ( VARCHAR(10) ,  @spid  )     
		EXEC sp_executesql @STR  
		FETCH NEXT FROM rs INTO @spid     
	END    
CLOSE rs    
DEALLOCATE rs    

