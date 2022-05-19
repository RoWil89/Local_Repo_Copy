/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

Report Name:	No Read Report

Author:			Craig Wilkins

Purpose:		When a meter reading is obtained there are two flows which are required to enter settlements, the D00010
				and the D0019 (register readings and register advances respectively). 
				This report aims to identify which settlement run MPANS may be impacting (i.e. are not settling on actual reads),
				by looking for the absence of meter advances. 
				It may not be settling due to lack of register readings or due to the lack of register advances.

Date Created:	2020.07.29

Date Tested:	n/a

Date Reviewed:	2020.07.30

Reviewed by:	Emma Navin, Naomi King, James Black (Business Stakeholders)

Notes:			Where no meter advances are found, the impacting date is set to supply start date.
				This may not be a true representation of settlement impact for new connections if they were De-Energised 
				from SSD until meter install.

Version / Edits:		0.1.2 
						0.1.1 Added profile class
						0.1.0 Everything is new!

To do / Considerations:	Peer review & Testing
						The settlement run is calculated using days - could be more acurate if refered to the calendar

\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


USE D0004;

IF OBJECT_ID('tempdb..#No_reads') IS NOT NULL
DROP TABLE #No_reads

IF OBJECT_ID('tempdb..#Runs') IS NOT NULL
DROP TABLE #Runs


SELECT

 MPAN
 ,Total_EAC
,CAST(EFSD AS DATE) AS 'EFSD'
,CASE
WHEN EAC_EFD IS NULL THEN CAST(EFSD AS DATE)
ELSE CAST(EAC_EFD AS DATE)
 END AS 'Settlement_Impact_Date'
 ,Dt_Last_Read AS 'Last_Read_Date'
 ,Profile_Class

INTO #No_reads

FROM D0004.dbo.d0004_weekly_settlement_report

WHERE MC = 'A'

AND ETSD IS NULL

AND Disconnection_Dt IS NULL

AND Energisation_Sts = 'E'

AND UNIQ_ID IN (SELECT MAX(UNIQ_ID)
FROM d0004_weekly_settlement_report
GROUP BY MPAN
)

SELECT DISTINCT

 MPAN
,Total_EAC
,Profile_Class
,Settlement_Impact_Date
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
,Last_Read_Date

INTO #Runs

FROM #No_reads

SELECT

	 Impacting_Run
	,COUNT(MPAN) AS 'MPAN_COUNT'
	,SUM(Total_EAC) AS 'TOTAL_EAC'

FROM #Runs

GROUP BY Impacting_Run, Run_Index
ORDER BY Run_Index ASC 

SELECT

	 MPAN
	,Total_EAC
	,Profile_Class
	,Settlement_Impact_Date
	,Days_Not_Settled
	,Impacting_Run
	,Run_Index
	,Last_Read_Date
	,CASE
		WHEN CAST(Settlement_Impact_Date AS DATE) = CAST(Last_Read_Date AS DATE) THEN 'Read_Required'
		ELSE 'Check_Data'
	 END AS 'Action'

FROM #Runs

-- where MPAN in ('1030032972114','1610021869895') These MPANS have issues with the EAC EFDs

ORDER BY Run_Index DESC