SELECT  t.name AS 'table',
        ( avg_total_user_cost * avg_user_impact ) * ( user_seeks + user_scans )
        AS 'potential_impact',
        'CREATE NONCLUSTERED INDEX ix_IndexName ON ' + SCHEMA_NAME(t.schema_id)
        + '.' + t.name COLLATE DATABASE_DEFAULT + ' ('
        + ISNULL(d.equality_columns, '')
        + CASE WHEN d.inequality_columns IS NULL THEN ''
               ELSE CASE WHEN d.equality_columns IS NULL THEN ''
                         ELSE ','
                    END + d.inequality_columns
          END + ') ' + CASE WHEN d.included_columns IS NULL THEN ''
                            ELSE 'INCLUDE (' + d.included_columns + ')'
                       END + ';' AS 'create_index_statement'
FROM    sys.dm_db_missing_index_group_stats AS s
        INNER JOIN sys.dm_db_missing_index_groups AS g
ON s.group_handle = g.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS d
ON g.index_handle = d.index_handle
        INNER JOIN sys.tables t WITH ( NOLOCK ) ON d.OBJECT_ID = t.OBJECT_ID
WHERE   d.database_id = DB_ID()
        AND s.group_handle IN (
        SELECT TOP 500 group_handle
        FROM sys.dm_db_missing_index_group_stats WITH ( NOLOCK )
        ORDER BY ( avg_total_user_cost * avg_user_impact ) *
                 ( user_seeks + user_scans ) DESC )
        --AND t.name LIKE 'Person'
ORDER BY ( avg_total_user_cost * avg_user_impact ) * ( user_seeks + user_scans ) DESC;
