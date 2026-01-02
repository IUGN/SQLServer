----------------------------------------------------------------
--создаем окружение


USE DBA;
GO


IF OBJECT_ID('dbo.JobSyncScripts') IS NOT NULL
    DROP TABLE dbo.JobSyncScripts;
GO


CREATE TABLE dbo.JobSyncScripts     --тут будет храниться выгрузка процедуры
(
    BatchID     INT NOT NULL,
    JobName     SYSNAME,
    ScriptText  NVARCHAR(MAX),
    CreatedDate DATETIME DEFAULT(GETDATE())
);




IF OBJECT_ID('dbo.JobSyncExclude') IS NOT NULL
    DROP TABLE dbo.JobSyncExclude;
GO


CREATE TABLE dbo.JobSyncExclude     --таблица для исключения джобов
    (
        JobName SYSNAME PRIMARY KEY
    );








IF OBJECT_ID('dbo.GenerateJobScripts') IS NOT NULL
    DROP PROCEDURE dbo.GenerateJobScripts;
GO


CREATE PROCEDURE dbo.GenerateJobScripts
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE @BatchID INT;


    -- Новый BatchID = MAX + 1
    SELECT @BatchID = ISNULL(MAX(BatchID), 0) + 1
    FROM dbo.JobSyncScripts;


    DECLARE @JobId UNIQUEIDENTIFIER,
            @JobName SYSNAME,
            @JobDescription NVARCHAR(512),
            @OwnerLoginName SYSNAME,
            @SQL NVARCHAR(MAX);


    DECLARE JobCursor CURSOR FAST_FORWARD FOR
        SELECT j.job_id,
               j.name,
               ISNULL(j.description, N'') AS description,
               sp.name AS owner_login_name
        FROM msdb.dbo.sysjobs j
        JOIN sys.server_principals sp ON j.owner_sid = sp.sid
        WHERE j.enabled = 1
          AND j.name NOT IN (SELECT JobName FROM DBA.dbo.JobSyncExclude);


    OPEN JobCursor;
    FETCH NEXT FROM JobCursor INTO @JobId, @JobName, @JobDescription, @OwnerLoginName;


    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = N'';


       
        -- Удаление джоба если он уже есть
       
        SET @SQL += N'IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N''' + @JobName + N''')
    EXEC msdb.dbo.sp_delete_job @job_name = N''' + @JobName + N''', @delete_unused_schedule=1;
';


       
        -- Создание джоба с description и владельцем
       
        SET @SQL += N'EXEC msdb.dbo.sp_add_job
    @job_name = N''' + @JobName + N''',
    @enabled = 1,
    @description = N''' + REPLACE(@JobDescription, '''', '''''') + N''',
    @owner_login_name = N''' + @OwnerLoginName + N''';
';


       
        -- Добавление шагов
       
        SELECT @SQL += '
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N''' + @JobName + ''',
    @step_name = N''' + js.step_name + ''',
    @subsystem = N''' + js.subsystem + ''',
    @command = N''' + REPLACE(REPLACE(js.command, '''', ''''''), CHAR(13)+CHAR(10), ' ') + ''',
    @on_success_action = ' + CAST(js.on_success_action AS NVARCHAR(10)) + ',
    @on_fail_action = ' + CAST(js.on_fail_action AS NVARCHAR(10)) + ';
'
        FROM msdb.dbo.sysjobsteps js
        WHERE js.job_id = @JobId
        ORDER BY js.step_id;


       
        -- Добавление расписаний
       
        SELECT @SQL += '
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N''' + @JobName + ''',
    @name = N''' + s.name + ''',
    @enabled = ' + CAST(s.enabled AS NVARCHAR(10)) + ',
    @freq_type = ' + CAST(s.freq_type AS NVARCHAR(10)) + ',
    @freq_interval = ' + CAST(s.freq_interval AS NVARCHAR(10)) + ',
    @freq_subday_type = ' + CAST(s.freq_subday_type AS NVARCHAR(10)) + ',
    @freq_subday_interval = ' + CAST(s.freq_subday_interval AS NVARCHAR(10)) + ',
    @active_start_time = ' + CAST(s.active_start_time AS NVARCHAR(10)) + ',
    @active_end_time = ' + CAST(s.active_end_time AS NVARCHAR(10)) + ';
'
        FROM msdb.dbo.sysjobschedules j
        JOIN msdb.dbo.sysschedules s ON j.schedule_id = s.schedule_id
        WHERE j.job_id = @JobId;


       
        -- Привязка джоба к серверу        
        SET @SQL += N'EXEC msdb.dbo.sp_add_jobserver @job_name = N''' + @JobName + N''', @server_name = N''(LOCAL)'';
';


       
        -- Сохраняем в таблицу с единым BatchID
       
        INSERT INTO dbo.JobSyncScripts (BatchID, JobName, ScriptText)
        VALUES (@BatchID, @JobName, @SQL);


        FETCH NEXT FROM JobCursor INTO @JobId, @JobName, @JobDescription, @OwnerLoginName;
    END;


    CLOSE JobCursor;
    DEALLOCATE JobCursor;


    PRINT 'Сгенерированы скрипты для BatchID = ' + CAST(@BatchID AS NVARCHAR(10));
END
GO


----------------------------------------------------------------
--создание окружения завершено
















----------------------------------------------------------------
--выполняем процедуру джобом


EXEC DBA.dbo.GenerateJobScripts;






----------------------------------------------------------------
--для проверки выгрузки


SELECT *
FROM dbo.JobSyncScripts
WHERE BatchID = (SELECT MAX(BatchID) FROM dbo.JobSyncScripts)
ORDER BY JobName;






----------------------------------------------------------------
--выполняем на реплике после свитчовера\фейловера (хоть джобом, хоть вручную)


USE DBA;
GO


DECLARE @BatchID INT;


-- Берем последний BatchID
SELECT @BatchID = MAX(BatchID)
FROM dbo.JobSyncScripts;


DECLARE @SQL NVARCHAR(MAX);


DECLARE JobCursor CURSOR FAST_FORWARD FOR
    SELECT ScriptText
    FROM dbo.JobSyncScripts
    WHERE BatchID = @BatchID
    ORDER BY JobName;


OPEN JobCursor;
FETCH NEXT FROM JobCursor INTO @SQL;


WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Выполняется скрипт для джоба...';


    SET @SQL = REPLACE(@SQL, CHAR(13) + CHAR(10) + 'GO', '');
    SET @SQL = REPLACE(@SQL, 'GO', '');


    EXEC sp_executesql @SQL;


    FETCH NEXT FROM JobCursor INTO @SQL;
END;


CLOSE JobCursor;
DEALLOCATE JobCursor;


PRINT 'Все джобы из BatchID ' + CAST(@BatchID AS NVARCHAR(10)) + ' успешно созданы';
GO










----------------------------------------------------------------
--так или иначе добавьте в исключения джобы которые не хотите переносить
--например джобы бэкапов, индексной оптимизации и т.п.




INSERT INTO dbo.JobSyncExclude (JobName)
    VALUES
('DBA_DatabaseBackup - SYSTEM_DATABASES - FULL'),
('DBA_GenerateLoginSyncScripts'),
('DBA_sp_purge_jobhistory')