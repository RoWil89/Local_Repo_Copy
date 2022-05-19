
-- =============================================
-- Author:			Dan Barker
-- Creation date:	13/05/2016
-- Description:		Returns Reads from AFMS and 
--					pivots by DC for given period
-- =============================================

-- AFMS Reads For Given Reporting Period ELEC.sql
-- EDIT 13/06/2016: Adapted to return DC at time of read rather than current DC
-- Currently returns all read types

USE AFMSLocal;

DECLARE @RepStart AS DATE;
DECLARE @RepEnd AS DATE;

-- *** ENTER DATES IN FORMAT MM/DD/YYYY ***
-- RepStart & RepEnd dates included in result set
SET @RepStart = '06/01/2018';
SET @RepEnd = '06/30/2018';

---- drop temp tables
--IF OBJECT_ID('tempdb.dbo.#afms','U') IS NOT NULL
--	DROP TABLE dbo.#afms;
--IF OBJECT_ID('tempdb.dbo.#temp','U') IS NOT NULL
--	DROP TABLE dbo.#temp;

-- return afms details to #afms
SELECT DISTINCT
	mp.J0003,			-- mpan
	mp.J0049,			-- efsd
	mp.J0117,			-- etsd
	-- EDIT 13/06/2016 ***
	CASE 
		WHEN ag.J0219 <= rr.J0016 THEN ag.J0205
		ELSE ah.AGENT_ID
		END AS J0205,
	--ag.J0205,			-- dc
	-- ***
	--rr.MET_REG_READ,	-- meter_reg_reading primary key -- causes a row to be returned for each register associated with read
	rr.J0016,			-- reading date and time
	rr.J0022,			-- validation status
	rr.J0171,			-- reading type
	rr.FLOW_RECEIVED,
	rr.DATE_RECEIVED,
	rr.J0332,			-- reading reason code -- may cause multiple rows to be returned for a read when more than one register from a read has a reason code
	mp.J0003 + '|' + CAST(rr.J0016 AS VARCHAR(20)) + '|' + rr.J0022 + '|' + rr.J0171 + '|' + rr.FLOW_RECEIVED + '|' + CAST(rr.DATE_RECEIVED AS VARCHAR(20)) AS UniqRead 
	-- used to return meter reading reason code per individual reads - identifies individual reads
INTO #afms
FROM dbo.mpan mp
	INNER JOIN dbo.meter me
		ON mp.UNIQ_ID = me.MPAN_LNK
	INNER JOIN dbo.agent ag
		ON mp.UNIQ_ID = ag.MPAN_LNK 
	LEFT JOIN dbo.meter_register mr
		ON me.METER_PK = mr.METER_FK
	LEFT JOIN [AFMSELECLIVEP4]..[CUSTOMER].[METER_REG_READING] rr
		ON mr.METER_REG_PK = rr.METER_REG_FK
		AND ( rr.DATE_RECEIVED >= @RepStart AND rr.DATE_RECEIVED <= @RepEnd )
-- *** EDIT 13/06/2016 
	LEFT JOIN OPENQUERY (AFMSELECLIVEP4, 'SELECT a.MPAN_LNK, a.AGENT_ID, a.AGENT_ROLE_CODE, a.AGENT_EFD, a.AGENT_ETD
													FROM CUSTOMER.AGENT_HISTORY a
													WHERE a.AGENT_ROLE_CODE = ''D''') AS ah	-- returns NHH DC's from AGENT_HISTORY table
		ON mp.UNIQ_ID = ah.MPAN_LNK
		AND ah.AGENT_EFD <= rr.J0016														-- AGENT_EFD <= read date
		AND ah.AGENT_ETD >= rr.J0016														-- AGENT_ETD >= read date
-- ***
WHERE mp.J0082 IN ( 'A', 'B' )
	AND rr.FLOW_RECEIVED NOT IN ( 'S0003', 'D0139', 'D0311' )
	AND rr.J0171 <> 'W'
	--AND rr.J0171 NOT IN ( ?, ?, ? ) -- Exclude any Reading Types? 

-- references #afms returns single row for read into #temp
-- returns all rejection reasons associated with a read to J0332 ';' seperated 
SELECT DISTINCT
	t.J0003,			-- mpan
	t.J0049,			-- efsd
	t.J0117,			-- etsd
	t.J0205,			-- dc
	t.J0016,			-- reading date and time
	t.J0022,			-- validation status
	t.J0171,			-- reading type
	t.FLOW_RECEIVED,
	t.DATE_RECEIVED,
	STUFF((SELECT DISTINCT '; ' + a.J0332 FROM #afms a WHERE a.UniqRead = t.UniqRead FOR XML PATH('')),1,1,'') AS J0332
INTO #temp
	FROM #afms t;

--return dataset
SELECT
	J0003 AS MPAN,
	J0049 AS EFSD,
	J0117 AS ETSD,
	J0205 AS Data_Collector,
	J0016 AS Read_Date,
	J0022 AS BSC_Validation_Status,
	J0171 AS Reading_Type,
	FLOW_RECEIVED,
	DATE_RECEIVED,
	J0332 AS Meter_Reading_Reason_Code
FROM #temp
ORDER BY DATE_RECEIVED, J0003;

--return summary pivot
WITH PivotData AS
(
SELECT
	J0205 AS Data_Collector,
	J0022 AS BSC_Validation_Status,
	J0003 AS ReadNum
FROM #temp
)
SELECT *
FROM PivotData
PIVOT(COUNT(ReadNum) 
FOR BSC_Validation_Status IN ( "V" , "F", "U" )) AS PivotResult
ORDER BY Data_Collector ASC;

--drop temp tables
DROP TABLE dbo.#afms;
DROP TABLE dbo.#temp;


