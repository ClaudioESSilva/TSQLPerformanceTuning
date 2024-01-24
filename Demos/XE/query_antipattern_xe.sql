USE master;
GO 
 
IF EXISTS (SELECT * 
           FROM   sys.dm_xe_sessions 
           WHERE  NAME = 'query_antipattern_xe') 
  BEGIN 
      DROP event session [query_antipattern_xe] ON server; 
  END
GO 
 
CREATE EVENT SESSION [query_antipattern_xe] ON SERVER  
     ADD EVENT sqlserver.query_antipattern (   
        ACTION(sqlserver.client_app_name,sqlserver.plan_handle, 
               sqlserver.query_hash,sqlserver.query_plan_hash,
               sqlserver.sql_text)
          ) ADD TARGET package0.ring_buffer(SET max_memory=(500)) 
GO


SELECT map_value 
FROM sys.dm_xe_map_values 
WHERE name = N'query_antipattern_type'; 