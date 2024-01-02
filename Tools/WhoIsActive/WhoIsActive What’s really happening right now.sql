EXEC sp_WhoIsActive  @output_column_list = '[dd%][session_id][%delta][login_name][sql_text][%]'  , @delta_Interval = 5;


Note three important things about this:
1. Column names are enclosed in brackets, and they are NOT comma separated.
2. A “%” wildcard is used before or after column names to include more results or reduce typing.
3. The final “[%]” wildcard all by itself indicates we want to return all remaining columns in the default order.

Источник <https://straightpathsql.com/archives/2023/01/5-common-sql-server-problems-to-troubleshoot-with-sp_whoisactive/> 



Источник <https://straightpathsql.com/archives/2023/01/5-common-sql-server-problems-to-troubleshoot-with-sp_whoisactive/> 
