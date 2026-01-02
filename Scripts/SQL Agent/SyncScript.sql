

--===============================================
--чтобы все запустить выполните скрипт до строки отмеченной как конец создания
--===============================================




USE [DBA] --база данных где будут храниться SP и сами логины




IF OBJECT_ID('dbo.SyncScript') IS NOT NULL
    DROP TABLE dbo.SyncScript;


CREATE TABLE [dbo].[SyncScript](        -- таблица для выгрузки логинов
    [ScriptID] [int] IDENTITY(1,1) NOT NULL,
    [BatchID] [uniqueidentifier] NOT NULL,
    [GeneratedOn] [datetime2](7) NOT NULL,
    [ScriptLine] [nvarchar](max) NOT NULL,
PRIMARY KEY CLUSTERED
(
    [ScriptID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]




ALTER TABLE [dbo].[SyncScript] ADD  DEFAULT (sysutcdatetime()) FOR [GeneratedOn]




CREATE PROCEDURE [dbo].[GenerateLoginSyncScripts]
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE @BatchID UNIQUEIDENTIFIER = NEWID();


   
    -- Логины (SQL и Windows)    
    INSERT INTO dbo.SyncScript (BatchID, ScriptLine)
    SELECT @BatchID,
    CASE
        WHEN sp.type = 'S' THEN
            'IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = ''' + sp.name + ''')
BEGIN
    CREATE LOGIN [' + sp.name + ']
    WITH PASSWORD = 0x' + CONVERT(VARCHAR(MAX), sl.password_hash, 2) + ' HASHED,
         SID = 0x' + CONVERT(VARCHAR(MAX), sp.sid, 2) + ',
         DEFAULT_DATABASE = [' + sp.default_database_name + '],
         DEFAULT_LANGUAGE = [' + sp.default_language_name + '],
         CHECK_POLICY = ' + CASE WHEN sl.is_policy_checked = 1 THEN 'ON' ELSE 'OFF' END + ',
         CHECK_EXPIRATION = ' + CASE WHEN sl.is_expiration_checked = 1 THEN 'ON' ELSE 'OFF' END + ';
END
ELSE
BEGIN
    ALTER LOGIN [' + sp.name + ']
    WITH PASSWORD = 0x' + CONVERT(VARCHAR(MAX), sl.password_hash, 2) + ' HASHED,
         DEFAULT_DATABASE = [' + sp.default_database_name + '],
         DEFAULT_LANGUAGE = [' + sp.default_language_name + '],
         CHECK_POLICY = ' + CASE WHEN sl.is_policy_checked = 1 THEN 'ON' ELSE 'OFF' END + ',
         CHECK_EXPIRATION = ' + CASE WHEN sl.is_expiration_checked = 1 THEN 'ON' ELSE 'OFF' END + ';
END;'
        WHEN sp.type = 'U' THEN
            'IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = ''' + sp.name + ''')
    CREATE LOGIN [' + sp.name + '] FROM WINDOWS
    WITH DEFAULT_DATABASE = [' + sp.default_database_name + '],
         DEFAULT_LANGUAGE = [' + sp.default_language_name + '];'
    END
    FROM sys.server_principals sp
    LEFT JOIN sys.sql_logins sl ON sp.principal_id = sl.principal_id
    WHERE sp.type IN ('S','U')
      AND sp.is_disabled = 0  -- только активные логины
      AND sp.name NOT LIKE '##%' -- исключаем временные логины
      AND sp.name <> 'sa' -- исключаем sa
      AND sp.name NOT LIKE 'NT SERVICE\%' -- исключаем сервисные логины
      AND sp.name NOT LIKE 'NT AUTHORITY\%' -- исключаем системные логины
      AND sp.name NOT LIKE 'BUILTIN\%'; -- исключаем встроенные логины


   
-- роли и участники    
    INSERT INTO dbo.SyncScript (BatchID, ScriptLine)
    SELECT @BatchID,
        'ALTER SERVER ROLE [' + r.name + '] ADD MEMBER [' + mbr.name + '];'
    FROM sys.server_role_members rm
    JOIN sys.server_principals r   ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE mbr.type IN ('S','U')
      AND mbr.name NOT LIKE '##%' -- также лишнее исключаем
      AND mbr.name <> 'sa'
      AND mbr.name NOT LIKE 'NT SERVICE\%'
      AND mbr.name NOT LIKE 'NT AUTHORITY\%'
      AND mbr.name NOT LIKE 'BUILTIN\%';


   
-- серверные разрешения    
    INSERT INTO dbo.SyncScript (BatchID, ScriptLine)
    SELECT @BatchID,
        perm.state_desc + ' ' + perm.permission_name + ' TO [' + sp.name + '];'
    FROM sys.server_permissions perm
    JOIN sys.server_principals sp ON perm.grantee_principal_id = sp.principal_id
    WHERE sp.type IN ('S','U')
      AND sp.is_disabled = 0
      AND sp.name NOT LIKE '##%'
      AND sp.name <> 'sa'
      AND sp.name NOT LIKE 'NT SERVICE\%'
      AND sp.name NOT LIKE 'NT AUTHORITY\%'
      AND sp.name NOT LIKE 'BUILTIN\%';


   
   
    SELECT @BatchID AS BatchID;
END
GO


--===============================================
--конец создания
--===============================================






----------------------------------------------------------------
--для запуска процедуры (упакуйте в джоб)
EXEC DBA.dbo.GenerateLoginSyncScripts; --специально добавляю префикс DBA на случай если база не выбрана




----------------------------------------------------------------
--просмотр собранных логинов
SELECT *
FROM dbo.SyncScript
WHERE BatchID = (SELECT TOP (1) BatchID FROM dbo.SyncScript ORDER BY GeneratedOn DESC);


----------------------------------------------------------------
--скрипт для применения логинов !!на реплике!! (упакуйте в джоб вторым шагом или запускайте вручную после свитчовера)
--специально применяется курсор т.к. существует ограничение на длину батча в 65К символов


USE DBA
DECLARE @BatchID UNIQUEIDENTIFIER;


SELECT TOP (1) @BatchID = BatchID
FROM dba.dbo.SyncScript
ORDER BY GeneratedOn DESC;


IF @BatchID IS NULL
BEGIN
    PRINT 'нет данных в dba.dbo.SyncScript';
    RETURN;
END


DECLARE @line NVARCHAR(MAX);


DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT ScriptLine
    FROM dba.dbo.SyncScript
    WHERE BatchID = @BatchID
    ORDER BY ScriptID;


OPEN cur;
FETCH NEXT FROM cur INTO @line;


WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC sys.sp_executesql @line;
    END TRY
    BEGIN CATCH
        PRINT 'ошибка в строке: ' + @line;
        PRINT ERROR_MESSAGE();
        CLOSE cur;
        DEALLOCATE cur;
        RETURN;
    END CATCH;


    FETCH NEXT FROM cur INTO @line;
END


CLOSE cur;
DEALLOCATE cur;