/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title: Electricity Rejected Reads Report
VERSION: 1
Author: Craig Wilkins
Date Created: 2020.08.25
Purpose: To create a view of NHH read rejections that are considered outstanding

Sections:	1:	Declare variables & drop temp tables if they exist
			2:	Create Rejection Reason Table
			3:	Create Read History Table
			4:  Create Register level Rejected Read Table
			5:	Add Age Brackets to the Rejected Reads
			6:	Create Register Level Valid Read Table
			7:	Create MPAN Level Valid Read - MPAN Combinations Table
			8:	Return Rejected Reads Data Set
			9:	Return Results - Data Table & Summary Table

Notes:	Duplication Issue:
			As of 27/08/2020 approx. 1.89% of rej reads returned are duplicated, due to:
					a) Different rejection reason for different reg's on the same meter
					b) Meter exchanges where the last valid read was the F/I read on the same day
					   causing the record to come up twice
			After discussing with the business owner(s) James Black and William Goodliffe - they agreed this was an 
			acceptable level of duplication and were happy with the output. 
			A long-term resolution should be found.

		Variable Output Issue:
			When run on the same day, the numbers retuned from the query have noted to be variable.
			Although not drastically different, the numbers have been seen to fluctuate by up to +/- 3
			rows each time the query is run - this is being investigated but isn't seen as being impactful
			enough to not use the query.


\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 1 - Declare variables & drop temp tables if they exist
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

USE AFMSLocal;

DECLARE @REPDATE DATE
SET @REPDATE = GETDATE()

IF OBJECT_ID('tempdb..#Read_Hist') IS NOT NULL
    DROP TABLE #Read_Hist

IF OBJECT_ID('tempdb..#Reason_Codes') IS NOT NULL
DROP TABLE #Reason_Codes

IF OBJECT_ID('tempdb..#Reg_Pos') IS NOT NULL
    DROP TABLE #Reg_Pos

IF OBJECT_ID('tempdb..#Rej_Reads') IS NOT NULL
    DROP TABLE #Rej_Reads

IF OBJECT_ID('tempdb..#Valid_Reg_Pos') IS NOT NULL
    DROP TABLE #Valid_Reg_Pos

IF OBJECT_ID('tempdb..#Valid_Reads') IS NOT NULL
    DROP TABLE #Valid_Reads

IF OBJECT_ID('tempdb..#Results') IS NOT NULL
    DROP TABLE #Results

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 2 - Create Rejection Reason Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

CREATE TABLE #Reason_Codes ([ID] CHAR(02), [Description] NVARCHAR(50))

INSERT INTO #Reason_Codes VALUES ('01', 'MSID Incorrect')
INSERT INTO #Reason_Codes VALUES ('02', 'Reading Dates < Previous Valid Read Date')
INSERT INTO #Reason_Codes VALUES ('03', 'Negative Consumption')
INSERT INTO #Reason_Codes VALUES ('04', 'Inconsistent with slave register advance')
INSERT INTO #Reason_Codes VALUES ('05', 'Consumption exceeds twice expected advance')
INSERT INTO #Reason_Codes VALUES ('06', 'Meter incorrectly energised')
INSERT INTO #Reason_Codes VALUES ('07', 'Meter incorrectly de-energised')
INSERT INTO #Reason_Codes VALUES ('08', 'Full Scale MD')
INSERT INTO #Reason_Codes VALUES ('09', 'Zero MD')
INSERT INTO #Reason_Codes VALUES ('10', 'Number of MD resets >1')
INSERT INTO #Reason_Codes VALUES ('11', 'Number of register digits incorrect')
INSERT INTO #Reason_Codes VALUES ('12', 'Inconsistent register read date')
INSERT INTO #Reason_Codes VALUES ('13', 'Faulty Meter')
INSERT INTO #Reason_Codes VALUES ('14', 'Hand Held Read Failure')
INSERT INTO #Reason_Codes VALUES ('15', 'Meter Not on Site/Metering protocol not approved')
INSERT INTO #Reason_Codes VALUES ('16', 'Standing Data incorrect')
INSERT INTO #Reason_Codes VALUES ('17', 'No access to meter')
INSERT INTO #Reason_Codes VALUES ('18', 'Meter Time/Date reset')
INSERT INTO #Reason_Codes VALUES ('19', 'Outstation reset')
INSERT INTO #Reason_Codes VALUES ('20', 'Meter Change/Meter Maintenance')
INSERT INTO #Reason_Codes VALUES ('21', 'Phase Failure')
INSERT INTO #Reason_Codes VALUES ('22', 'Meters Recording Zeros')
INSERT INTO #Reason_Codes VALUES ('23', 'Test Data Recorded')
INSERT INTO #Reason_Codes VALUES ('24', 'Data Lapse')
INSERT INTO #Reason_Codes VALUES ('25', 'Actual Data Manually Keyed')
INSERT INTO #Reason_Codes VALUES ('26', 'Invalid Zero Advances')
INSERT INTO #Reason_Codes VALUES ('27', 'Zero Consumption')

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 3 - Create Read History Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT

 M.UNIQ_ID
,M.J0003 as 'MPAN'
,J0004 as 'MSN'
,J0066 as 'GSP'
,M.J0081 as 'EAC'
,ME.METER_PK
,MR.METER_REG_PK
,J0332 as 'Meter Reading Reason Code'
,J0078 as 'TPR'
,MRR.J0016 AS 'Reading Date & Time'
,MRR.J0022 AS 'BSC Validation Status'
,MRR.J0171 AS 'Reading Type'
,MRR.J0040 AS 'Register Reading'
,MRR.FLOW_RECEIVED
,ROW_NUMBER() OVER (PARTITION BY J0003, J0078  ORDER BY J0003, J0078, J0016 DESC) AS 'Row_Number' 

INTO #Read_Hist

FROM AFMSLocal.dbo.mpan M

LEFT JOIN AFMSLocal.dbo.meter ME
ON M.UNIQ_ID = ME.MPAN_LNK

LEFT JOIN AFMSLocal.dbo.meter_register MR
ON ME.METER_PK = MR.METER_FK

LEFT JOIN AFMSLocal.dbo.meter_reg_reading MRR
ON MR.METER_REG_PK = MRR.METER_REG_FK 

WHERE UNIQ_ID IN (SELECT max(UNIQ_ID)
FROM AFMSLocal.dbo.mpan
GROUP BY J0003)

AND FLOW_RECEIVED IN ('D0010') -- is a meter read flow

AND J0082 = 'A' -- is NHH 

AND J0117 IS NULL -- is not a lost account

AND J0473 IS NULL --Is not Disconnected

AND MRR.J0016 BETWEEN '2010.01.01' AND GETDATE() -- in a set date range

AND J0103 = 'AI' -- the register type is active import (constaint needed to exclude non-settlement registers)


-- Test Output
--SELECT * FROM #Read_Hist
--WHERE MPAN = '1012353993455'
--ORDER BY Row_Number ASC


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 4 - Create Register level Rejected Read Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT

 MPAN
,GSP
,MSN
,EAC
,CAST([Reading Date & Time] as date) AS 'Read Date'
,[BSC Validation Status]
,[Meter Reading Reason Code]
,[Description]
,[Reading Type]
,TPR
,[Register Reading]
,DENSE_RANK() OVER (PARTITION BY MPAN ORDER BY TPR) AS 'Reg_position' -- added to enable pivot by register (there are too many TPR combos to use that)

INTO #Reg_Pos

FROM #Read_Hist R
JOIN #Reason_Codes
	ON R.[Meter Reading Reason Code] = #Reason_Codes.ID

WHERE Row_Number = 1

AND [BSC Validation Status] = 'F' -- is a failed Reading

ORDER BY [Read Date], MPAN, MSN, Reg_position

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 5 - Add Age Brackets to the Rejected Reads
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT *

,CASE
	WHEN [Read Date] <= DATEADD( m, -6, CAST(@REPDATE AS DATE)) THEN '>=6 MONTHS'
	WHEN [Read Date] <= DATEADD( m, -3, CAST(@REPDATE AS DATE)) THEN '>=3 & <6 MONTHS'
	WHEN [Read Date] <= DATEADD( m, -1, CAST(@REPDATE AS DATE)) THEN '>=1 & <3 MONTHS'
	WHEN [Read Date] <= DATEADD( d, -7, CAST(@REPDATE AS DATE)) THEN '>=1 WEEK & <1 MONTH'
ELSE '<1 WEEK'
END AS 'Bracket'
,CASE
	WHEN [Read Date] <= DATEADD( m, -6, CAST(@REPDATE AS DATE)) THEN '5'
	WHEN [Read Date] <= DATEADD( m, -3, CAST(@REPDATE AS DATE)) THEN '4'
	WHEN [Read Date] <= DATEADD( m, -1, CAST(@REPDATE AS DATE)) THEN '3'
	WHEN [Read Date] <= DATEADD( d, -7, CAST(@REPDATE AS DATE)) THEN '2'
ELSE '1'
END AS 'Bracket Index'

INTO #Rej_Reads

FROM #Reg_Pos

ORDER BY [Read Date], MPAN, MSN, Reg_position

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 6 - Create Register Level Valid Read Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT

 MPAN
,GSP
,MSN
,EAC
,CAST([Reading Date & Time] as date) AS 'Read Date'
,[BSC Validation Status]
,[Reading Type]
,TPR
,[Register Reading]
,DENSE_RANK() OVER (PARTITION BY MPAN ORDER BY TPR) AS 'Reg_position' -- added to enable pivot by register (there are too many TPR combos to use that)

INTO #Valid_Reg_Pos

FROM #Read_Hist R

WHERE [BSC Validation Status] = 'V' -- is a Valid Reading

ORDER BY [Read Date], MPAN, MSN, Reg_position

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 7 - Create MPAN Level Valid Read - MPAN Combinations Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/ 

SELECT DISTINCT

	MPAN
	,[Read Date]
	,[BSC Validation Status]
	,[Reading Type]

INTO #Valid_Reads

FROM #Valid_Reg_Pos

WHERE CONCAT(MPAN,'_',[Read Date]) in	(SELECT CONCAT(MPAN,'_',MAX([Read Date]))
										 FROM #Valid_Reg_Pos
										 GROUP BY MPAN)

ORDER BY MPAN, [Read Date]


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 8 - Return Rejected Reads Results Set
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT

	 #Rej_Reads.MPAN
	,#Rej_Reads.[Read Date] AS 'Rej_Read_Date'
	,#Rej_Reads.[BSC Validation Status]
	,[Description]
	,#Rej_Reads.[Reading Type] AS 'Rej_Read_Type'
	,Bracket
	,[Bracket Index]
	,#Valid_Reads.[Read Date] AS 'Last_Valid_Date'
	,#Valid_Reads.[Reading Type] AS 'Valid_Read_Type'
	,CASE
		WHEN #Valid_Reads.[Read Date] >= #Rej_Reads.[Read Date] THEN 'Resolved'
		WHEN #Rej_Reads.[Read Date] > #Valid_Reads.[Read Date]  THEN 'Unresolved'
		WHEN #Valid_Reads.[Read Date] IS NULL THEN 'Unresolved'
		ELSE 'Error'
		END AS 'Error_Status'

		INTO #Results

FROM #Rej_Reads
		LEFT JOIN #Valid_Reads
		ON #Rej_Reads.MPAN = #Valid_Reads.MPAN

WHERE CONCAT(#Rej_Reads.MPAN,'_',#Rej_Reads.[Read Date]) IN (	SELECT
																CONCAT(MPAN,'_',MAX([Read Date])) AS 'MPAN_Read_Date'
																FROM #Rej_Reads
																GROUP BY MPAN)
ORDER BY [Bracket Index] DESC


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 8 - Return Results & Summary Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT * FROM #Results

WHERE Error_Status IN ('Unresolved', 'Error');



SELECT

	  Bracket
	 ,COUNT(MPAN) AS 'Error_Count'
	 

FROM #Results

WHERE Error_Status IN ('Unresolved', 'Error')

GROUP BY Bracket, [Bracket Index]

ORDER BY [Bracket Index] ASC