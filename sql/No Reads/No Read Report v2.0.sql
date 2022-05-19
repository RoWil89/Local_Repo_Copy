
USE D0004

GO


--NB.New connections - NC flag may need to be added at some point to cat from install date rather than regi date
-- 2000057566702 - example New connection MPAN 

-- Checks for and removes existing temp tables

IF OBJECT_ID('tempdb..#Settlement_Data') IS NOT NULL
DROP TABLE #Settlement_Data

IF OBJECT_ID('tempdb..#Reads') IS NOT NULL
DROP TABLE #Reads

IF OBJECT_ID('tempdb..#Runs') IS NOT NULL
DROP TABLE #Runs

-- Creates and populates the #Settlement_Data temp table

CREATE TABLE #Settlement_Data
(
 MPAN VARCHAR (13) NULL
,REGI_EFSD DATE
,REGI_ETSD DATE
,EAC_EFD DATE
,Total_EAC NUMERIC (14,1) NULL
,AA_EFD DATE
,AA_ETD DATE
,Total_AA VARCHAR(16) NULL
,Profile_Class  INT NULL
,MC VARCHAR(1) NULL
,GSP_Grp VARCHAR(2) NULL
,Meter_Type VARCHAR(5) NULL
,Energisation_Sts VARCHAR(1) NULL
,SSC VARCHAR(5) NULL
,MO VARCHAR(4) NULL
,DA VARCHAR(4) NULL
,DC VARCHAR(4) NULL
,Last_Read_Date DATE NULL
)

INSERT INTO #Settlement_Data

(MPAN
,REGI_EFSD
,REGI_ETSD
,EAC_EFD
,Total_EAC
,AA_EFD
,AA_ETD
,Total_AA
,Profile_Class
,MC
,GSP_Grp
,Meter_Type
,Energisation_Sts
,SSC
,MO
,DA
,DC
,Last_Read_Date
)

SELECT

	 MPAN
	,CAST(EFSD AS DATE) AS 'REGI_EFSD'
	,CAST(ETSD AS DATE) AS 'REGI_ETSD'
	,CAST(EAC_EFD AS DATE) AS 'EAC_EFD'
	,Total_EAC
	,CASE
		WHEN AA_EFD IN ('ERR_1','ERR_2') THEN NULL
		ELSE DATEFROMPARTS(SUBSTRING(AA_EFD,1,4),SUBSTRING(AA_EFD,6,2),SUBSTRING(AA_EFD,9,2))
		END AS 'AA_EFD'
	,CASE
		WHEN AA_ETD IN ('ERR_1','ERR_2') THEN NULL
		ELSE DATEFROMPARTS(SUBSTRING(AA_ETD,1,4),SUBSTRING(AA_ETD,6,2),SUBSTRING(AA_ETD,9,2))
		END AS 'AA_ETD'
	,Total_AA
	,Profile_Class
	,MC
	,GSP_Grp
	,Meter_Type
	,Energisation_Sts
	,SSC
	,MO
	,DA
	,DC
	,CAST(Dt_Last_Read AS DATE) AS 'Last_Read_Date'

FROM D0004.dbo.d0004_weekly_settlement_report

WHERE UNIQ_ID IN (SELECT MAX(UNIQ_ID) FROM d0004_weekly_settlement_report GROUP BY MPAN)
AND (ETSD IS NULL OR ETSD > GETDATE())
AND Disconnection_Dt IS NULL
AND Energisation_Sts = 'E'
AND MC = 'A'
AND SSC NOT IN (
				SELECT SSC_ID
				FROM [DatSup].[dbo].[SSC_Type]
				WHERE SSC_Type = 'E'
				)

-- Populates the #Reads table

SELECT

 MPAN
,Total_EAC
,Total_AA
,REGI_EFSD
,
	CASE
		WHEN AA_ETD IS NULL AND EAC_EFD IS NULL THEN REGI_EFSD
		WHEN AA_ETD IS NULL AND EAC_EFD IS NOT NULL THEN EAC_EFD
		ELSE AA_ETD
		END AS 'Settlement_Impact_Date'
,	CASE
		WHEN AA_ETD IS NULL AND EAC_EFD IS NULL THEN 'REGI_EFSD'
		WHEN AA_ETD IS NULL AND EAC_EFD IS NOT NULL THEN 'EAC_EFD'
		ELSE 'AA_ETD'
		END AS 'Settlement_Impact_Type'
 ,Last_Read_Date
 ,Profile_Class
 ,Meter_Type
 ,GSP_Grp
 ,DC
 ,DA
 ,MO

 INTO #Reads

 FROM #Settlement_Data

 -- Populates the #Runs table

 SELECT
 
 MPAN
 ,Total_EAC
 ,Total_AA
 ,REGI_EFSD
 ,Settlement_Impact_Date
 ,Settlement_Impact_Type
 ,Last_Read_Date
 ,DATEDIFF(DAY,Settlement_Impact_Date,Last_Read_Date) AS 'Date_Diff'
 ,Profile_Class
 ,Meter_Type
 ,GSP_Grp
 ,DC
 ,DA
 ,MO
 ,DATEDIFF(day,Settlement_Impact_Date,GETDATE()) AS 'Days_Not_Settled'
,CASE
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 410 THEN 'RF'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 216 THEN 'R3'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 120 THEN 'R2'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 56 THEN 'R1'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 20 THEN 'SF'
ELSE 'II'
END AS 'Impacting_Run'
,CASE
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 410 THEN '5'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 216 THEN '4'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 120 THEN '3'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 56 THEN '2'
WHEN DATEDIFF(day,Settlement_Impact_Date,GETDATE()) >= 20 THEN '1'
ELSE '0'
END AS 'Run_Index' 

INTO #Runs
 
FROM #Reads

SELECT

 MPAN
,GSP_Grp
,Profile_Class
,Meter_Type
,Total_EAC
,Total_AA
,REGI_EFSD
,Last_Read_Date
,Settlement_Impact_Date
,Date_Diff
,Settlement_Impact_Type
,CASE
	WHEN Settlement_Impact_Type = 'AA_ETD' AND Date_Diff = 1 THEN 'Read_Required'
	WHEN Settlement_Impact_Type = 'AA_ETD' AND Date_Diff < 1 THEN 'Check_Data: AA_ETD > Last Read Date '
	WHEN Settlement_Impact_Type = 'AA_ETD' AND Date_Diff > 1 THEN 'Check_Data: AA_ETD < Last Read Date'
	WHEN Settlement_Impact_Type = 'EAC_EFD' AND Date_Diff = 0 THEN 'Read_Required'
	WHEN Settlement_Impact_Type = 'EAC_EFD' AND Date_Diff < 0 THEN 'Check_Data: EAC_EFD > Last Read Date'
	WHEN Settlement_Impact_Type = 'EAC_EFD' AND Date_Diff > 0 THEN 'Check_Data: EAC_EFD < Last Read Date'
	WHEN Settlement_Impact_Type = 'REGI_EFSD' AND Date_Diff = 0 THEN 'Read_Required'
	WHEN Settlement_Impact_Type = 'REGI_EFSD' AND Date_Diff > 0 THEN 'Check_Data: Missing Settlement Data' 
	WHEN Settlement_Impact_Type = 'REGI_EFSD' AND Last_Read_Date IS NULL THEN 'Check_Data: Missing CoS/I Read'
	WHEN Date_Diff IS NULL THEN 'Check_Data: Missing Read or Settleemtn Data'
	END AS 'Action'
,Days_Not_Settled
,Impacting_Run
,Run_Index

FROM #Runs


WHERE Profile_Class <> 8

ORDER BY Days_Not_Settled desc, Run_Index desc