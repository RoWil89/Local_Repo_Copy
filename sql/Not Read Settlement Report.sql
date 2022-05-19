/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title:			Not Read Settlement Report
VERSION:		1
Author:			Craig Wilkins
Date Created:	2019.07.10
Purpose:		To select MPANS which are not settling which can be worked by the settlement team

Sections:
				01: Checks for temp tables, deletes if they already exist
				02: Creates a temp SSC table - the table contains Export SSC's as identified in market domain data
					https://www.elexon.co.uk/operations-settlement/market-domain-data/ 
				03: Identifies the max registration and inserts into a temp table
				04: Create a temp table to identify customers with PSR
				05: Select MPAN information into a temp table to be used in filtering
				06: Join tables to create a results tables
				07:	Return results with the adition of business rules
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/

/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
						---- Section 01 ----
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/

set nocount on

IF OBJECT_ID('tempdb..#Temp_EFSD') IS NOT NULL
	DROP TABLE #Temp_EFSD

IF OBJECT_ID('tempdb..#Temp_Info') IS NOT NULL
	DROP TABLE #Temp_Info

IF OBJECT_ID('tempdb..#Export_SSC_Table') IS NOT NULL
	DROP TABLE #Export_SSC_Table

IF OBJECT_ID('tempdb..#RF_Worklist') IS NOT NULL
	DROP TABLE #RF_Worklist

IF OBJECT_ID('tempdb..#PSR') IS NOT NULL
	DROP TABLE #PSR

/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
						---- Section 02 ----
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/

CREATE TABLE #Export_SSC_Table(SSC nvarchar(4))

INSERT INTO #Export_SSC_Table (SSC) VALUES

 ('0482')
,('0483')
,('0484')
,('0485')
,('0486')
,('0487')
,('0488')
,('0489')
,('0490')
,('0491')
,('0492')
,('0493')
,('0494')
,('0495')
,('0496')
,('0497')
,('0498')
,('0940')
,('0941')


/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
						---- Section 03 ----
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/

SELECT
		MPAN
		,MAX(EFSD) AS 'EFSD'
		
INTO #Temp_EFSD			 

FROM D0004.dbo.d0004_weekly_settlement_report

GROUP BY MPAN

/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
						---- Section 04 ----
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT
	   P.BP
	  ,C.MPxN

  INTO #PSR

  FROM [lh-gendb-01].[BI_RAW].[dbo].[PSR_BPID_vw] P

  JOIN [lh-gendb-01].[Warehouse].[rep].[CSPEAR_LATEST_ROW_VW] C

  ON P.BP = C.[Business Partner]

  WHERE C.[Fuel type] = 'E'
  
/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
						---- Section 05 ----
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/

SELECT 

       [MPAN]
      ,[GSP_Grp]
      ,[MC]
      ,[EFSD]
      ,[ETSD]
      ,[Meter_Type]
      ,[Profile_Class]
      ,[Energisation_Sts]
      ,[Disconnection_Dt]
      ,[Read_Cycle]
      ,[SSC]
	  ,Dt_Last_Read
	  ,AA_ETD
	  ,CASE
		WHEN isdate(AA_ETD) = 1 THEN DATEDIFF(DAY,CONVERT(DATETIME,AA_ETD,121),Dt_Last_Read)
		ELSE NULL
		END AS 'D0019_Delay'
      ,[Dt_Last_D0004]
      ,[SVCCs_Associated_With_D0004]
	  ,S.[Description]
	  ,DA
	  ,DC
	  ,P.MPXN

  INTO #Temp_Info

  FROM [D0004].[dbo].[d0004_weekly_settlement_report] R

  INNER JOIN D0004.dbo.d0004_SVCC S

  ON R.SVCCs_Associated_With_D0004 = S.SVCC

  LEFT JOIN #PSR P

  ON R.MPAN = P.MPXN

  WHERE MPAN IN (SELECT MPAN FROM #Temp_EFSD)

  ORDER BY MPAN DESC

/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
						---- Section 06 ----
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/


SELECT 

	 E.MPAN
	,E.LatestVolume
	,E.ErrorType
	,E.InRun
	,I.GSP_Grp AS 'GSP'
	,I.EFSD
	,I.ETSD
	,I.Meter_Type
	,I.Profile_Class
	,I.Energisation_Sts
	,I.Disconnection_Dt
	,I.Dt_Last_Read AS 'Last Read Date'
	,DATEDIFF(DAY,Dt_Last_Read,GETDATE()) AS 'Days Since Last Read' 
	,I.AA_ETD
	,CASE
		WHEN D0019_Delay = 1 THEN 'Advance Received'
		WHEN D0019_Delay >1 THEN 'Missing AA'
		WHEN Dt_Last_Read IS NOT NULL AND AA_ETD IS NULL THEN 'Missing D0019'
		WHEN AA_ETD IS NOT NULL AND Dt_Last_Read IS NULL THEN 'Investigate'
		End AS 'D0019_Status'
	,I.Dt_Last_D0004
	,I.SVCCs_Associated_With_D0004
	,I.[Description] AS 'SVCC Description'
	,CASE
		WHEN I.SSC IN (SELECT * FROM #Export_SSC_Table) THEN 'E'
		ELSE 'I'
		END AS 'Import/Export Indiactor'
	,I.DA
	,I.DC
	,CASE
		WHEN I.MPXN IS NOT NULL THEN '1'
		ELSE '0'
		END AS 'PSR Indicator'

INTO #RF_Worklist

FROM D0019.wor.ErrorsWithStatus_VW E 

INNER JOIN #Temp_Info I

ON E.MPAN = I.MPAN

WHERE (ErrorStatus = 'IN PROGRESS' OR ErrorStatus IS NULL)

AND ErrorType IN ('D0004','REJECTED READS','NO READ')

--AND InRun = 'RF'

AND EndDateType NOT IN ('PENDING_ETSD', 'AA_EFD') 


/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
						---- Section 07 ----
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT

	MPAN
	,LatestVolume
	,ErrorType
	,InRun
	,EFSD
	,Meter_Type
	,Profile_Class
	,CASE
		WHEN Profile_Class BETWEEN 1 AND 2 THEN 'Domestic'
		WHEN Profile_Class > 2 THEN 'Business'
	 ELSE 'Unknown'
	 END AS 'Profile_Category'
	,GSP
	,Energisation_Sts
	,Disconnection_Dt
	,[Last Read Date]
	,AA_ETD
	,D0019_Status
	,[Days Since Last Read]
	,Dt_Last_D0004
	,SVCCs_Associated_With_D0004
	,[SVCC Description]
	,[Import/Export Indiactor]
	,DC
	,[PSR Indicator]

FROM #RF_Worklist

WHERE ETSD IS NULL
--AND Meter_Type not in ('S1')
AND Energisation_Sts = 'E'
AND Disconnection_Dt IS NULL
AND [Import/Export Indiactor] = 'I'
--AND SVCCs_Associated_With_D0004 NOT IN ('21', '18', '37', '39', '28')
--AND DC = 'SIEM'
--AND [PSR Indicator] = 0
AND D0019_Status != 'Investigate'
AND [Days Since Last Read] >= '180'  

ORDER BY [Last Read Date] ASC, LatestVolume