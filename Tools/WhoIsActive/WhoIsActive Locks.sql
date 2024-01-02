EXEC sp_WhoIsActive
    @find_block_leaders = 1,
    @sort_order = '[blocked_session_count] DESC'

--Источник <http://whoisactive.com/docs/23_leader/> 


EXEC sp_WhoIsActive  
@output_column_list = '[start_time][session_id][block%][login%][locks][sql_text][%]'  , @find_block_leaders = 1  , 
@get_locks = 1  , 
@get_additional_info = 1  , 
@sort_order = '[blocked_session_count] DESC';

--Источник <https://straightpathsql.com/archives/2023/01/5-common-sql-server-problems-to-troubleshoot-with-sp_whoisactive/> 