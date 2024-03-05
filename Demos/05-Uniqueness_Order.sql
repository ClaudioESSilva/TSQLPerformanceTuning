/*
	Example on how a @tableVariable OR #tmpTable with a PRIMARY KEY can help

	Good reasons to use @tableVariables?!
	 - Logging

	Bad:
	 - If estimates matter (before 2019 it estimates 1 row)
	 - If you want to leverage on parallelism (INSERTS)
*/
USE StackOverflow
GO

/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/


DECLARE @TableParameter TABLE
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO @TableParameter (Id, ClosedDate, CreationDate, Tags)
SELECT Id, ClosedDate, CreationDate, Tags
  FROM dbo.Posts
 WHERE ParentId = 0

SELECT TOP 10 tp.Id
  FROM dbo.Posts AS p
	INNER JOIN @TableParameter AS tp
	   ON p.Id = tp.Id
ORDER BY tp.Id

-- Table variable with a PK (and therefore with CLUSTERED INDEX)
DECLARE @TableParameterPK TABLE
(
	  Id			int	PRIMARY KEY
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO @TableParameterPK (Id, ClosedDate, CreationDate, Tags)
SELECT Id, ClosedDate, CreationDate, Tags
  FROM dbo.Posts
 WHERE ParentId = 0

SELECT TOP 10 tp.Id
  FROM dbo.Posts AS p
	INNER JOIN @TableParameterPK AS tp
	   ON p.Id = tp.Id
ORDER BY tp.Id

-- Where is the SORT?!




-- But I don't want to be PK because... I have duplicates
DECLARE @TableParameterIDX TABLE
(
	  Id			int				INDEX CI_ID CLUSTERED
	, ClosedDate	datetime		-- INDEX NCI_ClosedDate NONCLUSTERED
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO @TableParameterIDX (Id, ClosedDate, CreationDate, Tags)
SELECT Id, ClosedDate, CreationDate, Tags
  FROM dbo.Posts
 WHERE ParentId = 0

SELECT TOP 10 tp.Id
  FROM dbo.Posts AS p
	INNER JOIN @TableParameterIDX AS tp
	   ON p.Id = tp.Id
ORDER BY tp.Id



-- But I would encourage you to use #temp tables instead
DROP TABLE IF EXISTS #TableParameter
GO
CREATE TABLE #TableParameter
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO #TableParameter (Id, ClosedDate, CreationDate, Tags)
SELECT Id, ClosedDate, CreationDate, Tags
  FROM dbo.Posts
 WHERE ParentId = 0

SELECT TOP 10 tp.Id
  FROM dbo.Posts AS p
	INNER JOIN #TableParameter AS tp
	   ON p.Id = tp.Id
ORDER BY tp.Id


-- Table variable with a PK (and therefore with CLUSTERED INDEX)
DROP TABLE IF EXISTS #TableParameterPK
GO
CREATE TABLE #TableParameterPK
(
	  Id			int	PRIMARY KEY
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO #TableParameterPK (Id, ClosedDate, CreationDate, Tags)
SELECT Id, ClosedDate, CreationDate, Tags
  FROM dbo.Posts
 WHERE ParentId = 0

SELECT TOP 10 tp.Id
  FROM dbo.Posts AS p
	INNER JOIN #TableParameterPK AS tp
	   ON p.Id = tp.Id
ORDER BY tp.Id


/*
	Show the memory grant!
*/


/*
	Bottom line:
		Double-check if you query can't rely on the fact that the ORDER of the data 
		can help the engine selecting a better plan (avoiding SORT operators)
*/