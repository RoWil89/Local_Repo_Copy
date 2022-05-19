
IF OBJECT_ID('tempdb..#Read_Hist') IS NOT NULL
    DROP TABLE #Read_Hist


SELECT

 M.UNIQ_ID
,M.J0003 as 'MPAN'
,ME.METER_PK
,MR.METER_REG_PK
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

AND FLOW_RECEIVED IN ('D0010')

AND J0082 = 'A'

AND J0117 IS NULL

AND MRR.J0016 BETWEEN '2020.01.01' AND '2020.03.21'

AND MRR.J0022 = 'V'

AND J0103 = 'AI'

-- Return Data

SELECT DISTINCT TOP 10 

 MPAN
,CAST([Reading Date & Time] as date) AS 'Read Date'
,[BSC Validation Status]
,[Reading Type]
,TPR
,[Register Reading]
,DENSE_RANK() OVER (PARTITION BY MPAN ORDER BY TPR) AS 'Reg_position' 

FROM #Read_Hist R
WHERE Row_Number = 1

ORDER BY MPAN, TPR