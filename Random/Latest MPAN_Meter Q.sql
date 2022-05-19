
-- AFMS MSN by latest meter 

USE AFMSLocal; 

SELECT
     M.J0003 AS 'MPAN'
    ,M.J0049 AS 'Supply_Start_Date'
    ,M.J0117 as 'Supply_To_Date'
    ,ME.J0004 AS 'MSN'
    ,MR.J0010 AS 'Reg_ID'
    ,ME.J0848 AS 'Install_Date'
	,CONCAT(J0003,J0848) AS 'MPAN_Install'

FROM AFMSLocal.dbo.mpan M 

LEFT JOIN AFMSLocal.dbo.meter ME
    ON M.UNIQ_ID = ME.MPAN_LNK
LEFT JOIN AFMSLocal.dbo.meter_register MR
    ON ME.METER_PK = MR.METER_FK 

-- Is the max registration on the MPAN 

WHERE UNIQ_ID IN    (SELECT MAX(UNIQ_ID)
                     FROM AFMSLocal.dbo.mpan
                     GROUP BY J0003)  

-- Is the latest installed meter on the MPAN 

AND CONCAT(J0003,J0848) IN (SELECT CONCAT(J0003,MAX(ME.J0848))
                            FROM AFMSLocal.dbo.mpan M
                            lEFT JOIN AFMSLocal.dbo.meter ME
                                ON M.UNIQ_ID = ME.MPAN_LNK
							WHERE UNIQ_ID IN    (SELECT MAX(UNIQ_ID)
												 FROM AFMSLocal.dbo.mpan
												 GROUP BY J0003)
							GROUP BY J0003)

AND (M.J0117 IS NULL OR M.J0117 >= GETDATE())

ORDER BY J0003 asc, J0004 asc, J0010 asc;
