select DB_NAME(database_id) as db_name, name as logical_name, physical_name 
from sys.master_files 
WHERE database_id IN (
select database_id from sys.databases where state_desc = 'ONLINE')
order by 1;
