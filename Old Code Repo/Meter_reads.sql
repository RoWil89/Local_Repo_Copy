
-- sample data-- 

SELECT TOP 10 *

FROM AFMSLocal.dbo.mpan AS MP
	INNER JOIN AFMSLocal.dbo.meter AS ME
		ON MP.UNIQ_ID = ME.MPAN_LNK
	INNER JOIN AFMSLocal.dbo.meter_register AS MR
		ON ME.METER_PK = MR.METER_FK
	INNER JOIN AFMSLocal.dbo.meter_reg_reading AS MRR
		ON MR.METER_REG_PK = MRR.METER_REG_FK

-- Main Read Query --


--SELECT TOP 10

--	 MP.J0003 AS 'MPAN'
--	,MP.J0049 AS 'Effective_from_Settlement_Date {REGI}'
--	,MP.J0066 AS 'GSP_Group_Id'
--	,MP.J0071 AS 'Profile_Class_Id'
--	,MP.J0076 AS 'Standard_Settlement_Configuration_Id'
--	,MP.J0080 AS 'Energisation_Status'
--	,MP.J0082 AS 'Measurement_Class_Id'
--	,MP.J0117 AS 'Effective_to_Settlement_Date_{REGI}'
--	,MP.J0147 AS 'Line_Loss_Factor_Class_Id'
--	,MP.J0263 AS 'Metering_Point_Postcode'

--FROM AFMSLocal.dbo.mpan AS MP
--	INNER JOIN AFMSLocal.dbo.meter AS ME
--		ON MP.UNIQ_ID = ME.MPAN_LNK
--	INNER JOIN AFMSLocal.dbo.meter_register AS MR
--		ON ME.METER_PK = MR.METER_FK
--	INNER JOIN AFMSLocal.dbo.meter_reg_reading AS MRR
--		ON MR.METER_REG_PK = MRR.METER_REG_FK


SELECT TOP 10

	 MP.J0003 AS 'MPAN'
	,MP.J0049 AS 'Effective_from_Settlement_Date {REGI}'
	,MP.J0117 AS 'Effective_to_Settlement_Date_{REGI}'
	,ME.J0004 AS 'MSN'
	,ME.J0848 AS 'Meter_Installation_Date'
	,ME.ETD_MSID

FROM AFMSLocal.dbo.mpan AS MP
	INNER JOIN AFMSLocal.dbo.meter AS ME
		ON MP.UNIQ_ID = ME.MPAN_LNK
	INNER JOIN AFMSLocal.dbo.meter_register AS MR
		ON ME.METER_PK = MR.METER_FK
	INNER JOIN AFMSLocal.dbo.meter_reg_reading AS MRR
		ON MR.METER_REG_PK = MRR.METER_REG_FK

WHERE
-- is the latest registration for that MPAN
		UNIQ_ID IN (SELECT MAX(UNIQ_ID)
					FROM AFMSLocal.dbo.mpan
					GROUP BY J0003)
-- is for the latest meter on the MPAN
	AND ME.ETD_MSID IS NULL