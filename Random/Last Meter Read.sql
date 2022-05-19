USE AFMSLocal;

IF OBJECT_ID('tempdb..#Read_Hist') IS NOT NULL
    DROP TABLE #Read_Hist

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
SELECT * FROM #Read_Hist
WHERE CONCAT(MPAN,'_',[BSC Validation Status],'_',[Reading Date & Time]) 
												IN(
												SELECT CONCAT(J0003,'_',J0022,'_',MAX(J0016))
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

												GROUP BY J0003, J0022
												)

ORDER BY [Reading Date & Time] DESC, MPAN, MSN,TPR, [BSC Validation Status], rn ASC