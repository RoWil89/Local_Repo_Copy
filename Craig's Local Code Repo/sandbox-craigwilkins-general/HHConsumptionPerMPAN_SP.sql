USE [D0036]
GO

/****** Object:  StoredProcedure [D0036].[HHConsumptionPerMPAN]    Script Date: 18/06/2021 11:15:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

TITLE:		D0036 HH Consumption Per MPAN
VERSION:	2.0
AUTHOR:		Craig Wilkins
DATE:		2019.02.27
PURPOSE:	To return account level consumption details for a given settlement date / aggregation run combination

Sections:	1:	Set and define variables
					This code is required to return data for a given combination of settlement & aggregation dates. 
					The source for the variables is Elexon's DA settlement calendar (which uses market domain data).
					https://www.elexonportal.co.uk/article/view/1820?cachebust=bmvipfituw (A log in may be required to access)
					The USER is required to supply these dates.

			2:	Create and index 'Flowstamp' Temp Table 
					In order to improve performance of this querey a temp table of required data is created and indexed.
					It contains only data for the settlement date declared in section 1

			3: Create Measurement Class Temp Table
					Takes a view of measurement classes from AFMS Local - measurement class is required to identify
					sites Elexon are monitoring as part of a performance assurance technique
					https://www.elexon.co.uk/reference/performance-assurance/performance-assurance-techniques/

			4: Create Last Read Temp Table
					For most Half Hourly metered sites, data is submitted and available within a day of consumption.
					However, for some problem sites a meter reading agent will manually download data from the meter.
					In this case, we can receive data for the settlement date multiple times, and so we need to
					ensure we are selecting the most recently received set of data for that settlement date / aggregation run
					combination.

			5:	Results
					Returns a table of results for the given variables.
					
Edits:		2019.03.15:	Added indexed temp table to improve performance (section 2) and removed direct reference to D0036 DB
						in section 5
			2021.06.18: Changed the name of the #mc table to #AFMS, Joined to afms agent table and added:
						J0066 AS 'GSP' , J0205 AS 'DC', J0183 AS 'DA', J0178 AS 'MOP'.

\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
--CREATE PROCEDURE [D0036].[HHConsumptionPerMPAN]
	-- Add the parameters for the stored procedure here
	@SETDATE DATE, 
	@AGDATE DATE
AS
BEGIN

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 1 - Set and define variables
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

--Commented out as now part of stored procedure
/*
USE D0036;

DECLARE @SETDATE DATE
DECLARE @AGDATE DATE

SET @SETDATE = '2019.02.24'
SET @AGDATE =  '2019.03.13'
*/

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 2 - Create and index 'Flowstamp' Temp Table 
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

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

LEFT JOIN D0036.G101 G1
	ON 
		Z.PK_ZHV = G1.FK_ZHV
LEFT JOIN D0036.G102 G2
	ON
		G1.PK_101 = G2.FK_101
LEFT JOIN D0036.G103 G3
	ON 
		G2.PK_102 = G3.FK_102

	WHERE J0073 = @SETDATE

	AND J0103 = 'AI'

	ALTER TABLE #FlowStamp
	ADD CONSTRAINT PK_TempFlowStamp PRIMARY KEY CLUSTERED (Id)

	CREATE NONCLUSTERED INDEX ix_Flowstamp on #FlowStamp (FlowTstamp, J0003, J0103, J0073, J0020) INCLUDE ([J0177])

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 3 - Create Measurement Class Temp Table 
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#AFMS') IS NOT NULL
DROP TABLE #AFMS

SELECT

 J0003 AS 'MPAN'
,J0082 AS 'MC'
,J0066 AS 'GSP'
,J0205 AS 'DC'
,J0183 AS 'DA'
,J0178 AS 'MOP'

INTO #AFMS

FROM AFMSLocal.dbo.mpan
INNER JOIN AFMSLocal.dbo.agent
ON mpan.UNIQ_ID = agent.MPAN_LNK

WHERE UNIQ_ID IN	(SELECT MAX(UNIQ_ID)
					 FROM AFMSLocal.dbo.mpan
					 GROUP BY J0003)

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 4 - Create Last Read Temp Table 
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#last_read') IS NOT NULL
DROP TABLE #last_read

SELECT DISTINCT 

   J0003
  ,MAX(FlowTstamp) AS 'Max_Read_Date'

INTO #last_read

FROM D0036.ZHV Z

LEFT JOIN D0036.G101 G1
ON Z.PK_ZHV = G1.FK_ZHV
LEFT JOIN D0036.G102 G2
ON G1.PK_101 = G2.FK_101
LEFT JOIN D0036.G103 G3
ON G2.PK_102 = G3.FK_102

WHERE J0073 = @SETDATE

AND J0103 = 'AI'

AND FlowTstamp < @AGDATE

GROUP BY	 J0003


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 5 - Results 
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT

		 #FlowStamp.J0003 AS 'MPAN'
		,@AGDATE AS 'Run Date'
		,J0073 AS 'Settlement Date'
		,J0020 as 'Consumption Type'
		,#AFMS.MC AS 'Measurement Class'
		,#AFMS.DA AS 'DA'
		,#AFMS.DC AS 'DC'
		,#AFMS.MOP AS 'MOP'
		,#AFMS.GSP AS 'GSP'
		,COUNT(J0020) 'Count of Consumption type'
		,SUM(J0177) AS 'Metered Consumption'

FROM #FlowStamp

INNER JOIN #last_read
	ON #FlowStamp.J0003 = #last_read.J0003 
	AND FlowTstamp = #last_read.Max_Read_Date

LEFT JOIN #AFMS
	ON #FlowStamp.J0003 = #AFMS.MPAN

WHERE J0103 = 'AI'

AND J0073 = @SETDATE

GROUP BY 
	 #FlowStamp.J0003
	,J0073
	,J0020
	,MC
	,#last_read.Max_Read_Date
	,DA
	,DC 
	,MOP
	,GSP

ORDER BY [Metered Consumption] DESC

END
GO