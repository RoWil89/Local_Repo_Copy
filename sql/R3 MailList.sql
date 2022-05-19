
-- CHECK FOR AND DROP TEMP TABLES

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

-- CREATE TEMP SSC TABLE

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


-- Insert the maximum registration by MPAN into temp table

SELECT
		MPAN
		,MAX(EFSD) AS 'EFSD'
		
INTO #Temp_EFSD			 

FROM D0004.dbo.d0004_weekly_settlement_report

GROUP BY MPAN

-- INSERT A PSR/MPAN table from LH

SELECT DISTINCT
	   P.BP
	  ,C.MPxN

  INTO #PSR

  FROM [lh-gendb-01].[BI_RAW].[dbo].[PSR_BPID_vw] P

  JOIN [lh-gendb-01].[Warehouse].[rep].[CSPEAR_LATEST_ROW_VW] C

  ON P.BP = C.[Business Partner]

  WHERE C.[Fuel type] = 'E'

-- select mpan information into a temp table where it is the maximum registration

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
	,Dt_Last_Read
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

AND InRun in ('R3notRF', 'R3_ONLY')

AND EndDateType NOT IN ('PENDING_ETSD', 'AA_EFD') 

-- return filtered data

SELECT

	MPAN
	,LatestVolume
	,ErrorType
	,InRun
	,EFSD
	,Meter_Type
	,Profile_Class
	,GSP
	,Energisation_Sts
	,Disconnection_Dt
	,Dt_Last_Read
	,Dt_Last_D0004
	,SVCCs_Associated_With_D0004
	,[SVCC Description]
	,[Import/Export Indiactor]
	,DC
	,[PSR Indicator]

FROM #RF_Worklist

WHERE ETSD IS NULL
AND Meter_Type not in ('S1')
AND Energisation_Sts = 'E'
AND Disconnection_Dt IS NULL
AND [Import/Export Indiactor] = 'I'
AND SVCCs_Associated_With_D0004 NOT IN ('21', '18', '37', '39', '28')
AND DC = 'SIEM'
AND [PSR Indicator] = 0

ORDER BY LatestVolume DESC