
-- =============================================
-- Author:			Dan Barker
-- Creation date:	15/06/2016
-- Description:		Returns Reads from AFMS and 
--					pivots by MRA for given period.
-- =============================================

-- AFMS Reads For Given Reporting Period GAS NEW.sql

-- References both CNG AFMS & REN AFMS, returning reads when the LAST_UPD value is within the report period.
 
-- The MRA issues reads to us, the supplier, via a 210 flow this is then processed by AFMS and a UMR flow generated 
-- which is sent to Transco for validation. In response to the UMR a URS will be received from Transco - a URS_U10 
-- if the read has been accepted, a URS_U02 if the read has been rejected.


-- 210 - URS reads matched on MPRN_PK, MSN, Actual Read Date, Meter Reading. (The intermediate UMRs are not in the METER_READ table).
-- To do? Return URS only when Last_Upd post dates 210 last updated? ... Tried and tested - Performance suffers too much.

USE AFMSLocal;

DECLARE @RepStart AS DATE;
DECLARE @RepEnd AS DATE;
SET @RepStart = '02/22/2021';
SET @RepEnd = '02/28/2021';

DECLARE @SqlQuery AS VARCHAR(4000);
DECLARE @OpenQuery AS VARCHAR(4000);

--UMR flows sent based on entries in SHIP_GAS_CUST.FLOW_LOG
SELECT COUNT(FLOW_TYPE) AS "UMRs sent (REN FLOW_LOG)"
       FROM [P-OVL6-AFMSQL-1].SHIP_GAS_CUST.dbo.FLOW_LOG
       WHERE FLOW_TYPE LIKE 'UMR%'
	   AND PROCESS_TIMESTAMP >= @RepStart
	   AND PROCESS_TIMESTAMP >= @RepEnd

--URS flows received based on entries in SHIP_GAS_CUST.FLOW_LOG
SELECT COUNT(FLOW_TYPE) AS "URSs recd (REN FLOW_LOG)"
       FROM [P-OVL6-AFMSQL-1].SHIP_GAS_CUST.dbo.FLOW_LOG
       WHERE FLOW_TYPE LIKE 'URS%'
	   AND PROCESS_TIMESTAMP >= @RepStart
	   AND PROCESS_TIMESTAMP >= @RepEnd


--UMR flows sent based on entries in AFMS_GAS_CUST.FLOW_LOG
SELECT COUNT(FLOW_TYPE) AS "UMRs sent (REN FLOW_LOG)"
       FROM [P-OVL6-AFMSQL-1].AFMS_GAS_CUST.dbo.FLOW_LOG
       WHERE FLOW_TYPE LIKE 'UMR%'
	   AND PROCESS_TIMESTAMP >= @RepStart
	   AND PROCESS_TIMESTAMP >= @RepEnd

--URS flows received based on entries in AFMS_GAS_CUST.FLOW_LOG
SELECT COUNT(FLOW_TYPE) AS "URSs recd (REN FLOW_LOG)"
       FROM [P-OVL6-AFMSQL-1].AFMS_GAS_CUST.dbo.FLOW_LOG
       WHERE FLOW_TYPE LIKE 'URS%'
	   AND PROCESS_TIMESTAMP >= @RepStart
	   AND PROCESS_TIMESTAMP >= @RepEnd

-- drop temp tables if exist
IF OBJECT_ID('tempdb.dbo.#ren_temp','U') IS NOT NULL
	DROP TABLE dbo.#ren_temp;
IF OBJECT_ID('tempdb.dbo.#cng_temp','U') IS NOT NULL
	DROP TABLE dbo.#cng_temp;
IF OBJECT_ID('tempdb.dbo.#data','U') IS NOT NULL
	DROP TABLE dbo.#data;

--*** Return Reads from SHIP_GAS_CUST ***
-- return all URSs where read last updated date is within report range
WITH renURS AS
(
SELECT 
	sr.METER_READ_PK,
	sr.LAST_UPD,
	mp.MPRN_PK,
	mp.K0533,
	mp.K0116,
	mp.K0882,
	me.K0544,
	ag.K0559,
	sr.K0013,
	sr.K1168,
	sr.READ_STATUS,
	rj.K0798,	-- Rejection Reason
	sr.FLOW_RECEIVED,
	mp.SHIPPER,
	LTRIM(STR(mp.MPRN_PK,8,0)) + '|' + CAST(me.K0544 AS VARCHAR(14)) + '|' + CAST(sr.K0013 AS VARCHAR(10)) + '|' + LTRIM(STR(sr.K1168,10,0)) AS CompRead,
	LTRIM(STR(mp.MPRN_PK,8,0)) + '|' + CAST(me.K0544 AS VARCHAR(14)) + '|' + CAST(sr.K0013 AS VARCHAR(10)) + '|' + LTRIM(STR(sr.K1168,10,0)) + '|' + sr.READ_STATUS + '|' + sr.FLOW_RECEIVED + '|' + CAST(sr.LAST_UPD AS VARCHAR(10)) AS UniqRead
FROM gas.combined_mprn mp
	INNER JOIN gas.combined_meter me 
		ON mp.MPRN_PK = me.MPRN_FK
	LEFT JOIN gas.combined_agent ag
		ON mp.MPRN_PK = ag.MPRN_FK 
	INNER JOIN [P-OVL6-AFMSQL-1].[SHIP_GAS_CUST].dbo.[METER_READ] sr
	--INNER JOIN OPENQUERY([P-OVL6-AFMSQL-1], 'SELECT * FROM SHIP_GAS_CUST.METER_READ') AS sr -- slower!!
		ON mp.SHIPPER = 'REN'
		AND ( sr.LAST_UPD >= @RepStart AND sr.LAST_UPD <= @RepEnd )
		AND me.METER_PK - 90000000 = sr.METER_FK
	LEFT JOIN [P-OVL6-AFMSQL-1].[SHIP_GAS_CUST].dbo.[METER_READ_REJ_REASON] rj
		ON sr.METER_READ_PK = rj.METER_READ_FK
WHERE sr.FLOW_RECEIVED IN ( 'URS_U10', 'URS_U02' )
), ren210 AS 
-- return all 210s where read last updated date is within report start date - 14 days and report end date
(
SELECT 
	sr.METER_READ_PK,
	sr.LAST_UPD,
	mp.MPRN_PK,
	mp.K0533,
	mp.K0116,
	mp.K0882,
	ag.K0559,
	sr.K0013,
	sr.K1168,
	sr.READ_STATUS,
	rj.K0798,	-- Rejection Reason
	sr.FLOW_RECEIVED,
	mp.SHIPPER,
	LTRIM(STR(mp.MPRN_PK,8,0)) + '|' + CAST(me.K0544 AS VARCHAR(14)) + '|' + CAST(sr.K0013 AS VARCHAR(10)) + '|' + LTRIM(STR(sr.K1168,10,0)) AS CompRead
FROM gas.combined_mprn mp
	INNER JOIN gas.combined_meter me 
		ON mp.MPRN_PK = me.MPRN_FK
	LEFT JOIN gas.combined_agent ag
		ON mp.MPRN_PK = ag.MPRN_FK 
	INNER JOIN [P-OVL6-AFMSQL-1].[SHIP_GAS_CUST].dbo.[METER_READ] sr
		ON mp.SHIPPER = 'REN'
		AND ( sr.LAST_UPD >= DATEADD(d, -14, @RepStart) AND sr.LAST_UPD <= @RepEnd ) -- looks for 210s 14 days preceeding report date 
		AND me.METER_PK - 90000000 = sr.METER_FK
	LEFT JOIN [P-OVL6-AFMSQL-1].[SHIP_GAS_CUST].dbo.[METER_READ_REJ_REASON] rj
		ON sr.METER_READ_PK = rj.METER_READ_FK
WHERE sr.FLOW_RECEIVED = '210_210'
)
SELECT 
	r_u.METER_READ_PK,
	r_u.MPRN_PK,
	r_u.K0533,
	r_u.K0116,
	r_u.K0882,
	r_u.K0544,
	r_u.K0559,
	r_u.K0013,
	r_u.K1168,
	r_u.READ_STATUS,
	r_u.K0798,	-- Rejection Reason
	r_u.FLOW_RECEIVED AS FLOW_RECEIVED_URS,
	r_u.SHIPPER,
	r_u.CompRead,
	r_u.UniqRead,
	r_2.FLOW_RECEIVED AS FLOW_RECEIVED_210
INTO #ren_temp
FROM renURS AS r_u
	LEFT JOIN ren210 r_2
		ON r_u.CompRead = r_2.CompRead
		--AND r_u.LAST_UPD >= r_2.LAST_UPD --slows query considerably tried on join and as clause

-- references #ren_temp returns single row for read
-- returns all rejection reasons associated with a read to K0798 ';' separated 
SELECT DISTINCT
		t1.METER_READ_PK,
		t1.K0533,
		t1.MPRN_PK,
		t1.K0116,
		t1.K0882,
		t1.K0544, -- MSN needed for error check
		t1.K0559,
		t1.FLOW_RECEIVED_210,
		t1.K0013,
		t1.K1168,
		t1.FLOW_RECEIVED_URS,
		t1.READ_STATUS,
		t1.SHIPPER,
		STUFF((SELECT DISTINCT '; ' + a.K0798 FROM #ren_temp a WHERE a.UniqRead = t1.UniqRead FOR XML PATH('')),1,1,'') AS K0798
INTO #data
FROM #ren_temp t1
ORDER BY K0533;

--*** Return Reads from AFMS_GAS_CUST ***
-- return all URSs where read last updated date is within report range
WITH cngURS AS
(
SELECT 
	sr.METER_READ_PK,
	sr.LAST_UPD,
	mp.MPRN_PK,
	mp.K0533,
	mp.K0116,
	mp.K0882,
	me.K0544,
	ag.K0559,
	sr.K0013,
	sr.K1168,
	sr.READ_STATUS,
	rj.K0798,	-- Rejection Reason
	sr.FLOW_RECEIVED,
	mp.SHIPPER,
	LTRIM(STR(mp.MPRN_PK,8,0)) + '|' + CAST(me.K0544 AS VARCHAR(14)) + '|' + CAST(sr.K0013 AS VARCHAR(10)) + '|' + LTRIM(STR(sr.K1168,10,0)) AS CompRead,
	LTRIM(STR(mp.MPRN_PK,8,0)) + '|' + CAST(me.K0544 AS VARCHAR(14)) + '|' + CAST(sr.K0013 AS VARCHAR(10)) + '|' + LTRIM(STR(sr.K1168,10,0)) + '|' + sr.READ_STATUS + '|' + sr.FLOW_RECEIVED + '|' + CAST(sr.LAST_UPD AS VARCHAR(10)) AS UniqRead
FROM gas.combined_mprn mp
	INNER JOIN gas.combined_meter me 
		ON mp.MPRN_PK = me.MPRN_FK
	LEFT JOIN gas.combined_agent ag
		ON mp.MPRN_PK = ag.MPRN_FK 
	INNER JOIN [P-OVL6-AFMSQL-1].[AFMS_GAS_CUST].dbo.[METER_READ] sr
	--INNER JOIN OPENQUERY([P-OVL6-AFMSQL-1], 'SELECT * FROM AFMS_GAS_CUST.METER_READ') AS sr -- slower!!
		ON mp.SHIPPER = 'CNG'
		AND ( sr.LAST_UPD >= @RepStart AND sr.LAST_UPD <= @RepEnd )
		AND me.METER_PK = sr.METER_FK
	LEFT JOIN [P-OVL6-AFMSQL-1].[AFMS_GAS_CUST].dbo.[METER_READ_REJ_REASON] rj
		ON sr.METER_READ_PK = rj.METER_READ_FK
WHERE sr.FLOW_RECEIVED IN ( 'URS_U10', 'URS_U02' )
), cng210 AS 
-- return all 210s where read last updated date is within report start date - 14 days and report end date
(
SELECT 
	sr.METER_READ_PK,
	sr.LAST_UPD,
	mp.MPRN_PK,
	mp.K0533,
	mp.K0116,
	mp.K0882,
	ag.K0559,
	sr.K0013,
	sr.K1168,
	sr.READ_STATUS,
	rj.K0798,	-- Rejection Reason
	sr.FLOW_RECEIVED,
	mp.SHIPPER,
	LTRIM(STR(mp.MPRN_PK,8,0)) + '|' + CAST(me.K0544 AS VARCHAR(14)) + '|' + CAST(sr.K0013 AS VARCHAR(10)) + '|' + LTRIM(STR(sr.K1168,10,0)) AS CompRead
FROM gas.combined_mprn mp
	INNER JOIN gas.combined_meter me 
		ON mp.MPRN_PK = me.MPRN_FK
	LEFT JOIN gas.combined_agent ag
		ON mp.MPRN_PK = ag.MPRN_FK 
	INNER JOIN [P-OVL6-AFMSQL-1].[AFMS_GAS_CUST].dbo.[METER_READ] sr
		ON mp.SHIPPER = 'CNG'
		AND ( sr.LAST_UPD >= DATEADD(d, -14, @RepStart) AND sr.LAST_UPD <= @RepEnd ) -- looks for 210s 14 days preceeding report date 
		AND me.METER_PK = sr.METER_FK
	LEFT JOIN [P-OVL6-AFMSQL-1].[AFMS_GAS_CUST].dbo.[METER_READ_REJ_REASON] rj
		ON sr.METER_READ_PK = rj.METER_READ_FK
WHERE sr.FLOW_RECEIVED = '210_210'
)
SELECT 
	r_u.METER_READ_PK,
	r_u.MPRN_PK,
	r_u.K0533,
	r_u.K0116,
	r_u.K0882,
	r_u.K0544, 
	r_u.K0559,
	r_u.K0013,
	r_u.K1168,
	r_u.READ_STATUS,
	r_u.K0798,	-- Rejection Reason
	r_u.FLOW_RECEIVED AS FLOW_RECEIVED_URS,
	r_u.SHIPPER,
	r_u.CompRead,
	r_u.UniqRead,
	r_2.FLOW_RECEIVED AS FLOW_RECEIVED_210
INTO #cng_temp
FROM cngURS AS r_u
	LEFT JOIN cng210 r_2
		ON r_u.CompRead = r_2.CompRead
		--AND r_u.Last_UPD >= r_2.LAST_UPD

-- references #temp returns single row for read
---- selects highest METER_READ_PK where more than one URS matched to a 210
-- returns all rejection reasons associated with a read to K0798 ';' separated 
INSERT INTO #data ( METER_READ_PK, K0533, MPRN_PK, K0116, K0882, K0544, K0559, FLOW_RECEIVED_210, K0013, K1168, FLOW_RECEIVED_URS, READ_STATUS, SHIPPER, K0798 )
SELECT DISTINCT
		t1.METER_READ_PK,
		t1.K0533,
		t1.MPRN_PK,
		t1.K0116,
		t1.K0882,
		t1.K0544, -- MSN needed for error check
		t1.K0559,
		t1.FLOW_RECEIVED_210,
		t1.K0013,
		t1.K1168,
		t1.FLOW_RECEIVED_URS,
		t1.READ_STATUS,
		t1.SHIPPER,
		STUFF((SELECT DISTINCT '; ' + a.K0798 FROM #cng_temp a WHERE a.UniqRead = t1.UniqRead FOR XML PATH('')),1,1,'') AS K0798
FROM #cng_temp t1
ORDER BY K0533;

-- return dataset
SELECT 
	d.METER_READ_PK,
	d.K0533 AS MPRN,
	d.K0116 AS EFSD,
	d.K0882 AS ETSD,
	d.K0544 AS MSN,
	d.K0559 AS MRA,
	d.K0013 AS Actual_Read_Date,
	d.K1168 AS Meter_Reading,
	d.FLOW_RECEIVED_210,
	d.FLOW_RECEIVED_URS,
	d.READ_STATUS,
	d.K0798 AS Rejection_Reason,
	d.SHIPPER 
FROM #data d
WHERE d.READ_STATUS = 'FAILED'
ORDER BY d.K0533;

-- return summary pivot
WITH PivotData AS
(
SELECT
	K0559 AS MRA,
	READ_STATUS AS ReadStatus,
	K0533 AS ReadNum
FROM #data
)
SELECT *
FROM PivotData
PIVOT(COUNT(ReadNum) 
FOR ReadStatus IN ( "FAILED" )) AS PivotResult
ORDER BY MRA ASC;

DROP TABLE #ren_temp;
DROP TABLE #cng_temp;
DROP TABLE #data;