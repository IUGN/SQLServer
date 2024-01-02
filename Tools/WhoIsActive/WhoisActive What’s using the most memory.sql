EXEC sp_WhoIsActive  @output_column_list = '[dd%][session_id][%memory%][login_name][sql_text][%]'  , 
@get_memory_info = 1;

--Источник <https://straightpathsql.com/archives/2023/01/5-common-sql-server-problems-to-troubleshoot-with-sp_whoisactive/> 
