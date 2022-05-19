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

IF OBJECT_ID('tempdb..#Results') IS NOT NULL
    DROP TABLE #Results

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 2 - Create Rejection Reason Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

CREATE TABLE #Reason_Codes ([ID] CHAR(02), [Description] NVARCHAR(50))

INSERT INTO #Reason_Codes VALUES ('01', 'MSID Incorrect')
,('02', 'Reading Dates < Previous Valid Read Date')
,('03', 'Negative Consumption')
,('04', 'Inconsistent with slave register advance')
,('05', 'Consumption exceeds twice expected advance')
,('06', 'Meter incorrectly energised')
,('07', 'Meter incorrectly de-energised')
,('08', 'Full Scale MD')
,('09', 'Zero MD')
,('10', 'Number of MD resets >1')
,('11', 'Number of register digits incorrect')
,('12', 'Inconsistent register read date')
,('13', 'Faulty Meter')
,('14', 'Hand Held Read Failure')
,('15', 'Meter Not on Site/Metering protocol not approved')
,('16', 'Standing Data incorrect')
,('17', 'No access to meter')
,('18', 'Meter Time/Date reset')
,('19', 'Outstation reset')
,('20', 'Meter Change/Meter Maintenance')
,('21', 'Phase Failure')
,('22', 'Meters Recording Zeros')
,('23', 'Test Data Recorded')
,('24', 'Data Lapse')
,('25', 'Actual Data Manually Keyed')
,('26', 'Invalid Zero Advances')
,('27', 'Zero Consumption')

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 3 - Create Read History Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT

 M.UNIQ_ID
,M.J0003 as 'MPAN'
,ME.J0004 as 'MSN'
,M.J0066 as 'GSP'
,M.J0081 as 'EAC'
,ME.METER_PK
,MR.METER_REG_PK
,MRR.J0332 as 'Meter Reading Reason Code'
,MR.J0078 as 'TPR'
,MRR.J0016 AS 'Reading Date & Time'
,MRR.J0022 AS 'BSC Validation Status'
,MRR.J0171 AS 'Reading Type'
,MRR.J0040 AS 'Register Reading'
,MRR.FLOW_RECEIVED
,ROW_NUMBER() OVER (PARTITION BY M.J0003, MRR.J0022  
                    ORDER BY    MRR.J0016 DESC, 
                                --reason code is sometimes NULL when there are duplicate failures
                                --rank the code with the reason higher
                                CASE WHEN MRR.J0332 IS NULL THEN 1 ELSE 0 END) AS rn -- enables the latest reading of each type to be identified

INTO #Read_Hist

FROM AFMSLocal.dbo.mpan M

INNER JOIN AFMSLocal.dbo.meter ME
ON M.UNIQ_ID = ME.MPAN_LNK

INNER JOIN AFMSLocal.dbo.meter_register MR
ON ME.METER_PK = MR.METER_FK
AND MR.J0103 = 'AI' -- the register type is active import (constaint needed to exclude non-settlement registers)

INNER JOIN AFMSLocal.dbo.meter_reg_reading MRR
ON MR.METER_REG_PK = MRR.METER_REG_FK 
AND MRR.J0016 BETWEEN '2010.01.01' AND GETDATE() -- in a set date range
AND MRR.J0022 IN ('F','V') --only interested in these types for this report
AND MRR.FLOW_RECEIVED IN ('D0010') -- is a meter read flow

WHERE M.UNIQ_ID IN (SELECT max(UNIQ_ID)
FROM AFMSLocal.dbo.mpan
GROUP BY J0003)

AND M.J0082 = 'A' -- is NHH 

AND M.J0117 IS NULL -- is not a lost account

AND M.J0473 IS NULL --Is not Disconnected


-- Test Output
--SELECT * FROM #Read_Hist
--WHERE MPAN = '1170000628831'
--ORDER BY [BSC Validation Status],rn ASC

/*
Generate output
*/

;WITH failedCTE
AS
(
    /*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    Section 4 - Create Register level Rejected Read Table
    \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
    SELECT 
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

    FROM #Read_Hist R
    JOIN #Reason_Codes
	    ON R.[Meter Reading Reason Code] = #Reason_Codes.ID

    WHERE rn = 1 --the latest reading for this MPAN/BSC validation status

    AND [BSC Validation Status] = 'F' -- is a failed Reading

)
,failedReasonCTE
AS
(
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
    FROM failedCTE
)
,validCTE
AS
(
    /*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    Section 6 - Create Register Level Valid Read Table
    \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

    SELECT 
     MPAN
    ,GSP
    ,MSN
    ,EAC
    ,CAST([Reading Date & Time] as date) AS 'Read Date'
    ,[BSC Validation Status]
    ,[Reading Type]
    ,TPR
    ,[Register Reading]

    FROM #Read_Hist R

    WHERE rn = 1

    AND [BSC Validation Status] = 'V' -- is a Valid Reading
)
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 8 - Crate Rejected Reads Results Set
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
SELECT 
	 rr.MPAN
	,rr.[Read Date] AS 'Rej_Read_Date'
	,rr.[BSC Validation Status]
	,[Description]
	,rr.[Reading Type] AS 'Rej_Read_Type'
	,Bracket
	,[Bracket Index]
	,vr.[Read Date] AS 'Last_Valid_Date'
	,vr.[Reading Type] AS 'Valid_Read_Type'
	,CASE
		WHEN vr.[Read Date] >= rr.[Read Date] THEN 'Resolved'
		WHEN rr.[Read Date] > vr.[Read Date]  THEN 'Unresolved'
		WHEN vr.[Read Date] IS NULL THEN 'Unresolved'
		ELSE 'Error'
		END AS 'Error_Status'

	INTO #Results
FROM failedReasonCTE AS rr
		LEFT JOIN validCTE AS vr
		ON rr.MPAN = vr.MPAN



/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 9 - Return Results & Summary Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT * FROM #Results

WHERE Error_Status IN ('Unresolved', 'Error')
ORDER BY MPAN, Rej_Read_Date


SELECT

	  Bracket
	 ,COUNT(MPAN) AS 'Error_Count'
	 

FROM #Results

WHERE Error_Status IN ('Unresolved', 'Error')

GROUP BY Bracket, [Bracket Index]

ORDER BY [Bracket Index] ASC