EXEC sp_WhoisActive @get_memory_info =1, @output_column_list = '[start_time] [session_id] [sql_text] [query_plan] [wait_info] [%memory%]'
