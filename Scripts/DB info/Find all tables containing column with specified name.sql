--Search Tables:
SELECTc.name  AS'ColumnName',t.name AS'TableName'FROMsys.columns c
JOINsys.tables  t   ONc.object_id =t.object_id
WHEREc.name LIKE'%MyName%'ORDERBYTableName
            ,ColumnName;
--Search Tables and Views:
SELECTCOLUMN_NAME AS'ColumnName',TABLE_NAME AS'TableName'FROMINFORMATION_SCHEMA.COLUMNS
WHERECOLUMN_NAME LIKE'%MyName%'ORDERBYTableName
            ,ColumnName;

--Источник <https://stackoverflow.com/questions/4849652/find-all-tables-containing-column-with-specified-name-ms-sql-server> 