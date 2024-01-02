SELECT  name
        ,size*8.0/1024 'Current Size in MB' 
FROM    tempdb.sys.database_files 
--------- Below query would show Iniial size of TempDB files -----------
SELECT  name
        ,size*8.0/1024  'Initial Size in MB'
FROM master.sys.sysaltfiles WHERE dbid = 2  