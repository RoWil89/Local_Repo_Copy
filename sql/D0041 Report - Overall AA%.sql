/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title: D0041 Report - Overall AA%
VERSION: 2
Author: Craig Wilkins
Date Created: 2018.02.09
Purpose: Summaries D0041 data (to get a view of AA%) for the declared variables (Settlement Date and Settlement Run)

					[AA%, or percentage settled on annualized advanced is an industry standard calculation which takes
					total energy settled on actual reads (AA) and divides that by total energy ( AA + EAC (estimated energy))
					to give the percentage. Industry targets are as follows:

					Non Half Hourly AA% Targets 

					RF: 97% settled on AA within 14 months
					R3: 80% settled on AA within 6 months
					R2: 60% settled on AA within 3 months
					R1: 30% settled on AA within 1 month 
					
					Source: ANNEX S-1: PERFORMANCE LEVELS AND SUPPLIER CHARGES
							https://www.elexon.co.uk/wp-content/uploads/2017/03/Section_S-1_v10.0.pdf ]

Report Range: Variable - please enter report start and end dates based on the settlement date - not a run date

Sections:	1:	Drops existing temp tables and declares variables
			2:	Set Variables
			3:	Creates and populates temp SSC table
			4:  Creates and populates temp AA table
			5:	Creates and populates Temp EAC Table
			6:	Creates and populates Temp Volume Table
			7:	Create AA Summary Table
			8:  Create EAC Summary Table
			9:	For Testing Summary Tables
			10: Summary Query
			11:	Drops temp tables

UPDATE: 2018.06.29 - Addition of export SSC temp table to clean up the code and create one reference point to update
					[SSC's (standard settlement configurations) are held in market domain data and will
					get updated from time to time. SSC's which are for export metering do not count towards aa%]

					NB - an annual review of export SSC's from MDD should be made

!ALERT!: 2018.07.10 - A DA data outage occurred from the 04/07/2018 - 09/07/2018 and has effected the following
					  runs and settlement dates:

						RF: From 16/05/2017 to 21/05/2017
						R3: From 28/11/2017 to 03/12/2017
						R2: From 11/03/2018 to 14/03/2018
						R1: From 16/05/2018 to 21/05/2018 

					  As a result data for these settlement dates is incorrect and should be excluded from any reporting.

\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 1 - Drop existing temp tables & declares variables
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

USE D0041

IF OBJECT_ID('tempdb..#AA_TEMP') IS NOT NULL
	DROP TABLE #AA_TEMP

IF OBJECT_ID('tempdb..#EAC_TEMP') IS NOT NULL
	DROP TABLE #EAC_TEMP

IF OBJECT_ID('tempdb..#Volumes_TEMP') IS NOT NULL
	DROP TABLE #Volumes_TEMP

IF OBJECT_ID('tempdb..#AA_Summary') IS NOT NULL
	DROP TABLE #AA_Summary

IF OBJECT_ID('tempdb..#EAC_Summary') IS NOT NULL
	DROP TABLE #EAC_Summary

IF OBJECT_ID('tempdb..#Export_SSC_Table') IS NOT NULL
	DROP TABLE #Export_SSC_Table

DECLARE @RepStart DATE
DECLARE @RepEnd DATE
DECLARE @RunTypeVal CHAR(2)

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 2 ------------------------------------Set Variables-------------------------------------------
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SET @RepStart = '2018.10.26'
SET @RepEnd = '2018.10.29'
SET @RunTypeVal = 'R1'


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 3 - Creates and populates temp SSC table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

CREATE TABLE #Export_SSC_Table(SSC nvarchar(3))

INSERT INTO #Export_SSC_Table (SSC) VALUES

 ('482')
,('483')
,('484')
,('485')
,('486')
,('487')
,('488')
,('489')
,('490')
,('491')
,('492')
,('493')
,('494')
,('495')
,('496')
,('497')
,('498')
,('940')
,('941')

--Test SSC table update
--SELECT * FROM #Export_SSC_Table

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 4 - Creates and populates temp AA table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT
	
	settlementDate,
	S.flowReference,
	A.GSP_Group,
	S.PC,
	S.Distributor,
	S.LLF,
	S.SSC,
	S.Total_AA_MSID_Count

INTO #AA_TEMP

FROM [VMS-PND-001].D0041.dbo.FilesRead A
     INNER JOIN [VMS-PND-001].D0041.dbo.Readings S
      ON A.flowReference = S.flowReference

WHERE settlementCode = @RunTypeVal
AND settlementDate BETWEEN @RepStart AND @RepEnd
AND S.SSC NOT IN

				(SELECT * FROM #Export_SSC_Table)

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 5 - Creates and populates Temp EAC Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT

settlementDate,
s.flowReference,
a.GSP_Group,
s.PC,
s.Distributor,
s.LLF,
s.SSC,
s.Total_EAC_MSID_Count,
s.Default_EAC_MSID_Count

INTO #EAC_TEMP 

FROM [VMS-PND-001].D0041.dbo.FilesRead A
     INNER JOIN [VMS-PND-001].D0041.dbo.Readings S
      ON A.flowReference = S.flowReference

WHERE settlementCode = @RunTypeVal
AND settlementDate BETWEEN @RepStart AND @RepEnd
AND S.SSC NOT IN

				(SELECT * FROM #Export_SSC_Table)

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 6 - Creates and populates Temp Volume Table
	[EAC and AA % calculations as outlined in the BSC ANNEX S-1: PERFORMANCE LEVELS AND SUPPLIER CHARGES]
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT

FilesRead.settlementDate,
SUM (D0041.dbo.Readings.Total_AA) AS 'Total AA',
SUM (D0041.dbo.Readings.Total_EAC) AS 'Total EAC',
SUM (D0041.dbo.Readings.Total_AA) + SUM (D0041.dbo.Readings.Total_EAC) AS 'Total_Energy',
FORMAT(ROUND ((SUM (D0041.dbo.Readings.Total_AA)/ (SUM (D0041.dbo.Readings.Total_AA) + SUM (D0041.dbo.Readings.Total_EAC))),4),'P') AS 'AA %',
FORMAT(ROUND ((SUM (D0041.dbo.Readings.Total_EAC)/ (SUM (D0041.dbo.Readings.Total_AA) + SUM (D0041.dbo.Readings.Total_EAC))),4),'P') AS 'EAC %'

INTO #Volumes_TEMP

FROM [VMS-PND-001].D0041.dbo.FilesRead
     INNER JOIN [VMS-PND-001].D0041.dbo.Readings
      ON FilesRead.flowReference = Readings.flowReference

WHERE settlementCode = @RunTypeVal
AND settlementDate BETWEEN @RepStart AND @RepEnd
AND Readings.SSC NOT IN 

				(SELECT * FROM #Export_SSC_Table)

GROUP BY FilesRead.settlementDate

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 7 - Create AA Summary Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT

settlementDate
,SUM(Total_AA_MSID_Count) AS 'AA_MSID_Count'

INTO #AA_Summary

FROM #AA_TEMP 

GROUP BY settlementDate

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 8 - Create EAC Summary Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT 

	settlementDate
	,SUM(Default_EAC_MSID_Count) AS 'Default_EAC_MSID_Count'
	,SUM(Total_EAC_MSID_Count) AS 'EAC_MSID_Count'
	,SUM(Default_EAC_MSID_Count)+SUM(Total_EAC_MSID_Count) AS 'TOTAL_EAC_COUNT'

INTO #EAC_Summary

FROM #EAC_TEMP

GROUP BY settlementDate 

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 9 - Test
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

--SELECT * FROM #AA_TEMP
--SELECT * FROM #EAC_TEMP
--SELECT * FROM #Volumes_TEMP
--SELECT * FROM #AA_Summary
--SELECT * FROM #EAC_Summary

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 10 - Summary Query
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT distinct

	#EAC_Summary.settlementDate,
	#EAC_Summary.Default_EAC_MSID_Count,
	#EAC_Summary.EAC_MSID_Count,
	#EAC_Summary.TOTAL_EAC_COUNT,
	#AA_Summary.AA_MSID_Count,
	#Volumes_TEMP.[Total AA],
	#Volumes_TEMP.[Total EAC],
	#Volumes_TEMP.Total_Energy,
	#Volumes_TEMP.[AA %],
	#Volumes_TEMP.[EAC %]

FROM

#EAC_Summary
JOIN #AA_Summary ON #EAC_Summary.settlementDate = #AA_Summary.settlementDate
JOIN #Volumes_TEMP ON #EAC_Summary.settlementDate = #Volumes_TEMP.settlementDate

ORDER BY #EAC_Summary.settlementDate

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 11 - Drops Temp Tables
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

DROP TABLE #AA_TEMP
DROP TABLE #EAC_TEMP
DROP TABLE #Volumes_TEMP
DROP TABLE #AA_Summary
DROP TABLE #EAC_Summary
DROP TABLE #Export_SSC_Table