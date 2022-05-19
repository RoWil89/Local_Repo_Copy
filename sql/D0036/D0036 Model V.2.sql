

--

USE D0036
GO

IF OBJECT_ID('tempdb..#FlowStamp') IS NOT NULL
	DROP TABLE #FlowStamp

-- SECTION 1

DECLARE @MC VARCHAR(1) = 'C'

DECLARE @Count INT = 1

--Section 2

DECLARE @variables AS TABLE (

	    id  INT         IDENTITY(1, 1) NOT NULL
		,[Sett Date] DATE
		,[DA Run Date] DATE
		,[Sett Code] VARCHAR(2)
);

INSERT INTO @variables
(
		 [Sett Date]
		,[DA Run Date]
		,[Sett Code]
)
VALUES

('2019-02-01','2019-02-05','II'),
('2019-02-02','2019-02-05','II'),
('2019-02-03','2019-02-05','II'),
('2019-02-04','2019-02-06','II'),
('2019-02-05','2019-02-07','II'),
('2019-02-06','2019-02-08','II'),
('2019-02-07','2019-02-11','II'),
('2019-02-08','2019-02-12','II'),
('2019-02-09','2019-02-12','II'),
('2019-02-10','2019-02-12','II'),
('2019-02-11','2019-02-13','II'),
('2019-02-12','2019-02-14','II'),
('2019-02-13','2019-02-15','II'),
('2019-02-14','2019-02-18','II'),
('2019-02-15','2019-02-19','II'),
('2019-02-16','2019-02-19','II'),
('2019-02-17','2019-02-19','II'),
('2019-02-18','2019-02-20','II'),
('2019-02-19','2019-02-21','II'),
('2019-02-20','2019-02-22','II'),
('2019-02-21','2019-02-25','II'),
('2019-02-22','2019-02-26','II'),
('2019-02-23','2019-02-26','II'),
('2019-02-24','2019-02-26','II'),
('2019-02-25','2019-02-27','II'),
('2019-02-26','2019-02-28','II'),
('2019-02-27','2019-03-01','II'),
('2019-02-28','2019-03-04','II');

DECLARE @Min_Set DATE = (select min([Sett Date]) from @Variables)

DECLARE @Max_Set DATE = (select max([Sett Date]) from @Variables)


--Section 3

IF OBJECT_ID('tempdb..#FlowStamp') IS NOT NULL
	DROP TABLE #FlowStamp

CREATE TABLE #FlowStamp (

	   Id  INT         IDENTITY(1, 1) NOT NULL
	  ,[PK_ZHV] int not null
	  ,[Filename] varchar (255) not null
      ,[ArchiveDt] date not null
      ,[FileID] char (10) not null
      ,[FlowVersion] char (8) not null
      ,[FromRole] char (1) null
      ,[FromMPID] char (4) not null 
      ,[ToRole] char (1) null
      ,[ToMPID] char (4) not null  
      ,[FlowTstamp] datetime not null
      ,[SendAppID] varchar(5) null
      ,[RecAppID] varchar(5) null
      ,[BCast] char (1) null
      ,[TestFlag] varchar (4) not null
	  ,[PK_101] int not null
      ,[FK_ZHV] int not null
      ,[J0003] char (13) not null
      ,[J0103] char (2) not null
      ,[J0084] char (4) not null
	  ,[PK_102] int not null
      ,[FK_101] int not null
      ,[J0073] date not null
	  ,[PK_103] int not null
      ,[FK_102] int not null
      ,[J0020] char (1) not null
      ,[J0177] numeric (8,1) not null

);

INSERT INTO #FlowStamp
(
	   [PK_ZHV]
	  ,[Filename]
      ,[ArchiveDt]
      ,[FileID]
      ,[FlowVersion] 
      ,[FromRole] 
      ,[FromMPID] 
      ,[ToRole] 
      ,[ToMPID] 
      ,[FlowTstamp] 
      ,[SendAppID] 
      ,[RecAppID] 
      ,[BCast] 
      ,[TestFlag] 
	  ,[PK_101] 
      ,[FK_ZHV] 
      ,[J0003] 
      ,[J0103] 
      ,[J0084] 
	  ,[PK_102] 
      ,[FK_101] 
      ,[J0073]
	  ,[PK_103] 
      ,[FK_102] 
      ,[J0020] 
      ,[J0177] 
)

SELECT DISTINCT *

FROM D0036.ZHV Z

LEFT JOIN D0036.D0036.G101 G1
	ON 
		Z.PK_ZHV = G1.FK_ZHV
LEFT JOIN D0036.D0036.G102 G2
	ON
		G1.PK_101 = G2.FK_101
LEFT JOIN D0036.D0036.G103 G3
	ON 
		G2.PK_102 = G3.FK_102

	WHERE J0073 BETWEEN @Min_Set AND @Max_Set

	AND J0103 = 'AI'

	ALTER TABLE #FlowStamp
	ADD CONSTRAINT PK_TempFlowStamp PRIMARY KEY CLUSTERED (Id)

	CREATE NONCLUSTERED INDEX ix_Flowstamp on #FlowStamp (FlowTstamp, J0003, J0103, J0073, J0020) INCLUDE ([J0177])

-- Section 4

IF OBJECT_ID('tempdb..#Result') IS NOT NULL
DROP TABLE #Result

CREATE TABLE #Result

    (
		 [Settlement Date] DATE NULL
		,[Run date] DATE NULL
		,[Settlement Run] VARCHAR (2) NULL
		,[Actual Consumption] NUMERIC (8,1) NULL
		,[Estimated Consumption] NUMERIC (8,1) NULL
		,[AA%] DECIMAL (38,4) NULL 
    )

-- Section 5

IF OBJECT_ID('tempdb..#MC') IS NOT NULL
	DROP TABLE #MC

SELECT

	 M1.J0003 AS 'MPAN'
	,J0082 AS 'MC'

INTO #MC

FROM AFMSLocal.dbo.mpan M1

INNER JOIN 

	(SELECT

	  J0003
	 ,MAX(J0049)AS 'MAX_REGI'

	FROM AFMSLocal.dbo.mpan

	GROUP BY J0003) M2

		ON	M1.J0003 = M2.J0003
			AND M1.J0049 = M2.MAX_REGI

CREATE CLUSTERED INDEX ix_MC On #MC (MPAN)
CREATE NONCLUSTERED INDEX ix_MC2 On #MC (MC) INCLUDE (MPAN)

-- Section 6

DECLARE @MAXCount INT = (SELECT MAX(id) FROM @Variables)
DECLARE @SETDATE DATE = (SELECT [Sett Date] FROM @Variables WHERE id = @Count)
DECLARE @AGDATE DATE = (SELECT [DA Run Date] FROM @Variables WHERE id = @Count)
DECLARE @Run VARCHAR (2) = (SELECT [Sett Code] FROM @Variables WHERE id = @Count)

-- Section 7

WHILE @Count <= @MAXCount

BEGIN

-- Section 8

		IF OBJECT_ID('tempdb..#last_read') IS NOT NULL
			DROP TABLE #last_read

		IF OBJECT_ID('tempdb..#Act_values') IS NOT NULL
			DROP TABLE #Act_values

		IF OBJECT_ID('tempdb..#Est_values') IS NOT NULL
		DROP TABLE #Est_values

-- Section 9

SELECT DISTINCT 

				J0003
				,MAX(FlowTstamp) AS 'Max_Read_Date'

		into #last_read

		FROM #FlowStamp

		WHERE J0073 = @SETDATE

		AND FlowTstamp < @AGDATE
		
		AND J0103 = 'AI'

		GROUP BY J0003;

-- Section 10

SELECT DISTINCT

J0073 AS 'Settlement Date'
,SUM(J0177) AS 'Actual Consumption'

INTO #Act_values

FROM #FlowStamp

INNER JOIN #last_read
	ON
		#FlowStamp.J0003 = #last_read.J0003 AND
		#FlowStamp.FlowTstamp = #last_read.Max_Read_Date

LEFT JOIN #MC
	ON
		#FlowStamp.J0003 = #MC.MPAN

WHERE J0103 = 'AI'

	AND J0073 = @SETDATE

	AND J0020 = 'A'
	
	AND #MC.MC = @MC 

GROUP BY 
	 J0073
	,J0020

-- Section 11

SELECT DISTINCT

	 J0073 AS 'Settlement Date'
	,SUM(J0177) AS 'Estimated Consumption'

INTO #Est_values

FROM #FlowStamp

INNER JOIN #last_read
	ON
		#FlowStamp.J0003 = #last_read.J0003 AND
		#FlowStamp.FlowTstamp = #last_read.Max_Read_Date
LEFT JOIN #MC
	ON
		#FlowStamp.J0003 = #MC.MPAN


WHERE J0103 = 'AI'

AND J0073 = @SETDATE

AND #MC.MC = @MC

AND J0020 = 'E'

GROUP BY 
	 J0073
	,J0020

-- Section 11

INSERT INTO #Result

	(
			[Settlement Date] 
		,[Run date]
		,[Settlement Run]
		,[Actual Consumption]
		,[Estimated Consumption]
		,[AA%]
	)

		SELECT 

			 #Act_values.[Settlement Date]
			,@AGDATE AS 'Run date'
			,@Run AS 'Settlement Run'
			,#Act_values.[Actual Consumption]
			,#Est_values.[Estimated Consumption]
			,ROUND(SUM([Actual Consumption]) / (SUM([Actual Consumption])+SUM([Estimated Consumption])),4) AS 'AA%'

		FROM #Act_values
		INNER JOIN #Est_values
			ON 
				#Act_values.[Settlement Date] = #Est_values.[Settlement Date]

		GROUP BY

			 #Act_values.[Settlement Date]
			,#Act_values.[Actual Consumption]
			,#Est_values.[Estimated Consumption]

-- Section 12

    SET @Count += 1
	SET @SETDATE = (SELECT [Sett Date] FROM @Variables WHERE id = @Count)
	SET @AGDATE  = (SELECT [DA Run Date] FROM @Variables WHERE id = @Count)
	SET @Run  = (SELECT [Sett Code] FROM @Variables WHERE id = @Count)

-- Section 13

	DECLARE @PrintMessage NVARCHAR(50) =
	 CAST(@COUNT AS NVARCHAR(30))
	 + N' Of '
	 +CAST(@MAXCount AS NVARCHAR(30));

	DECLARE @ts AS VARCHAR(10) = CONVERT(CHAR(10), SYSDATETIME() , 108);
    RAISERROR( 'Timestamp %s', 1, 0, @ts) WITH NOWAIT;
    RAISERROR( 'Progress %s', 1, 0, @PrintMessage) WITH NOWAIT;

END

-- Section 14

SELECT * FROM #Result