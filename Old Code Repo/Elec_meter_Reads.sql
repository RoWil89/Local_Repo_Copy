/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title: Electricity Read Report
VERSION: 0.1
Author: Craig Wilkins
Date Created: 2021.02.16
Purpose: To create a view of NHH reads 

Sections:	1:	Declare variables & drop temp tables if they exist
			2:	Create Read History Table
					-Read history table at a TPR level returns over 3.1 million rows
					-Pulling all rows from that temp table directly takes approx 4 mins
			3:	Return Results

\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Create Read History Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


IF OBJECT_ID('tempdb..#Read_Hist') IS NOT NULL
    DROP TABLE #Read_Hist


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Create Read History Table
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
AND MR.J0103 = 'AI' -- the register type is active import (needed to exclude non-settlement registers)

INNER JOIN AFMSLocal.dbo.meter_reg_reading MRR
ON MR.METER_REG_PK = MRR.METER_REG_FK 
AND MRR.J0016 BETWEEN '2010.01.01' AND GETDATE() -- in a set date range
AND MRR.J0022 IN ('F','V', 'U') --only interested in these types for this report
AND MRR.FLOW_RECEIVED IN ('D0010', 'D0086') -- is a meter read flow

WHERE M.UNIQ_ID IN (SELECT max(UNIQ_ID)
FROM AFMSLocal.dbo.mpan
GROUP BY J0003)

AND M.J0082 = 'A' -- is NHH 

AND M.J0117 IS NULL -- is not a lost account

AND M.J0473 IS NULL --Is not Disconnected

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Temp Table Test
/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

--select * from #Read_Hist

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Extract last valid read
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT
	 MPAN
	,GSP
	,MSN
	,TPR
	,[Meter Reading Reason Code]
	,[Reading Date & Time]
	,[BSC Validation Status]
	,[Reading Type]
	,[Register Reading]
	,FLOW_RECEIVED
	,rn

FROM #Read_Hist

WHERE rn = 1
AND [BSC Validation Status] = 'V'
ORDER BY MPAN,[BSC Validation Status],TPR,rn


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Extract last failed read
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT
	 MPAN
	,GSP
	,MSN
	,TPR
	,[Meter Reading Reason Code]
	,[Reading Date & Time]
	,[BSC Validation Status]
	,[Reading Type]
	,[Register Reading]
	,FLOW_RECEIVED
	,rn

FROM #Read_Hist

WHERE rn = 1
AND [BSC Validation Status] = 'F'
ORDER BY MPAN,[BSC Validation Status],TPR,rn