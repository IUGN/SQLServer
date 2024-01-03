/* Get Details of Object on different filegroup
Finding Objects on Specific Filegroup*/
SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name] FROM sys.indexes i
INNER JOIN sys.filegroups f
ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o
ON i.[object_id] = o.[object_id] WHERE i.data_space_id = f.data_space_id
AND i.data_space_id = 2 -- Filegroup
GO

--Источник <https://blog.sqlauthority.com/2009/06/01/sql-server-list-all-objects-created-on-all-filegroups-in-database/> 
