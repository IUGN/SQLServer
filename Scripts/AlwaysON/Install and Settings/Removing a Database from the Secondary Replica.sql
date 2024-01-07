-- Remove Sales database from the availability group on Secondary Replica
 ALTER DATABASE [Sales] SET HADR OFF;

/*
Observe that the Sales database is in a restoring state. 
Moreover, there is a red cross on the Sales database under the Availability Databases node, 
indicating that the database is not a part of the availability group.*/
