EXEC sp_WhoIsActive  @output_column_list = '[start_time][session_id][temp%][sql_text][query_plan][wait_info][%]'  , 
@get_plans = 1  ,
@sort_order = '[tempdb_current] DESC';

--Источник <https://straightpathsql.com/archives/2023/01/5-common-sql-server-problems-to-troubleshoot-with-sp_whoisactive/> 