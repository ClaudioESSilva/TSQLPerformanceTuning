USE StackOverflow
GO

/*
	TURN ON ACTUAL PLAN, STATISTICS and LIVE QUERY STATISTICS

	SET STATISTICS TIME, IO ON
*/
SELECT DISTINCT U.Id
  FROM dbo.Posts P
	INNER JOIN dbo.Users U
	   ON P.OwnerUserId = U.Id
	   OR P.LastEditorUserId = U.AccountId






















-- We can re-write in the following manner
SELECT U.Id
	FROM dbo.Posts P
	INNER JOIN dbo.Users U
		ON P.OwnerUserId = U.Id
UNION
SELECT U.Id
	FROM dbo.Posts P
	INNER JOIN dbo.Users U
		ON P.LastEditorUserId = U.AccountId
GO




-- Oh BATCH_MODE_ADAPTIVE_JOINS (configuration_id = 9) kicked in! That's why, right?
SELECT * FROM sys.database_scoped_configurations
GO


-- Turn OFF BATCH_MODE_ADAPTIVE_JOINS scoped configuration
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_ADAPTIVE_JOINS = OFF
GO


-- Revert config
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_ADAPTIVE_JOINS=ON
GO
