/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title:			Gas - Last Accepted Meter Reads
VERSION:		1.2
Author:			Craig Wilkins
Contributors:	Derek Nicholls
Server(s):		P-OVL6-afmsql-1
Dastabase(s):	AccessReporting
Date Created: 2021.02.24
Purpose: To show the last accepted read for each live gas MPRN/Meter by date for read performance reporting 

Sections:	
			1:	Create and populate ranked read history table
				(Gets all accepted reads on all gas meters)
			2:	Create and populate Live MPRN table
				(Gets all live MPRNS , and ensures they are the latest registration period)
			3:  Create and populate Live Meter table
				(Gets the latest meter per MPRN)
			4:  Create and populate Interim Results Table
				(Joins the previous tables together into a results table)
			5:	Return Results
				(Adds an age bracket and a Bracket index to the results set based on the last accepted read date)
				* Where the Accepted read date is NULL, the supply start date is used *

Info:	K number descriptions can be found here: http://lh-afmsapp1:7000/UtiligroupCatalogueViewer/

Versions	1.0 - Everything is new!
			1.1 - Age bracket & Bracket index added (2021.03.04)
			1.2 -  Changed row number constraint from where clause to the join to bring in MPRNs with no reads
				- Added 'Date_Type' to describe the Accepted Read Date
				- Added 'No Read' as a bracket to distinguish between unread sites and the age of read sites
				- Added bracket index of -1 spesifically for unread sites


\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

USE AccessReporting;

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 1 - Create and populate ranked meter read history table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#MeterReadHistory') IS NOT NULL
	DROP TABLE #MeterReadHistory

CREATE TABLE #MeterReadHistory (
	 [ID]											INT IDENTITY(1, 1) NOT NULL
	,[METER_FK]										NUMERIC(38,0) NOT NULL
	,[K0013]										DATETIME NULL				-- Actual Read Date
	,[K1168]										VARCHAR (12) NULL			-- Read
	,[K0779]										VARCHAR(1) NULL				-- Read Type
	,[FLOW_RECEIVED]								VARCHAR (20) NULL
	,[RN]											INT NOT NULL
);

INSERT INTO #MeterReadHistory
(
  	 [METER_FK]
	,[K0013]
	,[K1168]
	,[K0779]
	,[FLOW_RECEIVED]
	,[RN]
)

SELECT
	 METER_FK
	,K0013
	,K1168
	,K0779
	,FLOW_RECEIVED
	,ROW_NUMBER() OVER (PARTITION BY METER_FK ORDER BY METER_READ_PK DESC ) AS RN --Gives a row number for each meter read on each meter

    FROM AccessReporting.SHIP_GAS_CUST.Meter_Read

    WHERE READ_STATUS = 'ACCEPTED' 
    AND FLOW_RECEIVED IN ('ONJOB','ONJOB_RETRO','ONUPD','ONUPD_RETRO','SAR','URS_U10','UT005_C41');

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 2 - Create and populate Live MPRN table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#LiveMPRN') IS NOT NULL
	DROP TABLE #LiveMPRN

CREATE TABLE #LiveMPRN (
	 [ID]											INT IDENTITY(1, 1) NOT NULL
	,[K0533] 										VARCHAR(20) NOT NULL		 --MPRN
	,[Max_PK]										NUMERIC(38,0) NOT NULL
);

INSERT INTO #LiveMPRN
(
  	  [K0533]
	 ,[Max_PK]
)
    SELECT 
		K0533,
		MAX(MPRN_PK) AS MPK
    FROM AccessReporting.SHIP_GAS_CUST.MPRN
    WHERE STATUS_CODE_FK NOT IN ('3','7','9','22','25','27','28','29','30','31')
    AND (K0882 IS NULL OR K0882 >= GETDATE())
    GROUP BY K0533;

--SELECT * FROM #LiveMPRN

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 3 - Create and populate Live Meter table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#LiveMeter') IS NOT NULL
	DROP TABLE #LiveMeter


CREATE TABLE #LiveMeter (
	 [ID]											INT IDENTITY(1, 1) NOT NULL
	,[MPRN_FK]										NUMERIC(38,0) NOT NULL
	,[METPK]										NUMERIC(38,0) NOT NULL
);

INSERT INTO #LiveMeter
(
  	  [MPRN_FK]
	 ,[METPK]
)

SELECT
	 MPRN_FK
	,MAX(meter_PK) AS METPK 
FROM SHIP_GAS_CUST.METER 
GROUP BY MPRN_FK;

--SELECT * FROM #LiveMeter

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 4 - Create Interim Results Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#InterimResults') IS NOT NULL
	DROP TABLE #InterimResults


CREATE TABLE #InterimResults (
	 [ID]										INT IDENTITY(1, 1) NOT NULL
	,[MPRN]										VARCHAR (10) NOT NULL
	,[Supply_Start_Date]						DATETIME NOT NULL
	,[Read_Date]								DATETIME NULL
	,[Read]										VARCHAR(12) NULL
	,[Read_Type]								VARCHAR(1) NULL
	,[Flow_Received]							VARCHAR (20) NULL
);

INSERT INTO #InterimResults
(
	 [MPRN]
	,[Supply_Start_Date]
	,[Read_Date]
	,[Read]
	,[Read_Type]
	,[Flow_Received]
)

SELECT

  #LiveMPRN.K0533 AS 'MPRN'
 ,MP.K0116 AS 'Supply_Start_Date'
 ,CAST(#MeterReadHistory.K0013 AS DATE) AS 'Read_Date'
 ,#MeterReadHistory.K1168 AS 'Read'
 ,#MeterReadHistory.K0779 AS 'Read_Type'
 ,#MeterReadHistory.FLOW_RECEIVED


FROM #LiveMPRN
	LEFT JOIN #LiveMeter
		ON #LiveMPRN.Max_PK = #LiveMeter.MPRN_FK
	LEFT JOIN #MeterReadHistory
		ON #LiveMeter.METPK = #MeterReadHistory.METER_FK AND #MeterReadHistory.RN = '1'
	LEFT JOIN AccessReporting.SHIP_GAS_CUST.MPRN MP
		ON #LiveMPRN.Max_PK = MP.MPRN_PK;  
--WHERE RN = 1; *Moved to the join with Meter Read History Table*

-- SELECT * FROM #InterimResults;

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 5 - Return Results
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

WITH Results AS
(
SELECT

	 MPRN
	,[Read]
	,CASE
		WHEN Read_Date IS NULL THEN CAST(Supply_Start_Date AS DATE)
		ELSE CAST(Read_Date AS DATE)
		END AS 'Accepted_Read_Date'
	,CASE
		WHEN Read_Date IS NULL AND Flow_Received IS NULL THEN 'SSD - NO ACCEPTED READ'
		WHEN Read_Date IS NULL AND Flow_Received = 'ONUPD' THEN 'SSD - Deemed Read'
		ELSE 'Actual Read'
		END AS 'Date_Type'
	,Read_Type
	,Flow_Received

FROM #InterimResults
)

SELECT
	 MPRN
	,[Read]
	,Accepted_Read_Date
	,Read_Type
	,Flow_Received
	,Date_Type
    ,CASE
		WHEN Date_Type = 'SSD - NO ACCEPTED READ' THEN 'No Read'
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -4, CAST(GETDATE() AS DATE)) THEN '>= 4 Years'
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -3, CAST(GETDATE() AS DATE)) THEN '>= 3 Years & < 4 Years'
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -2, CAST(GETDATE() AS DATE)) THEN '>= 2 Years & < 3 Years'
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -1, CAST(GETDATE() AS DATE)) THEN '>= 1 Year & < 2 Years'
	    WHEN Accepted_Read_Date <= DATEADD( m, -6, CAST(GETDATE() AS DATE)) THEN '>=6 Months & < 1 Year'
		WHEN Accepted_Read_Date <= DATEADD( m, -1, CAST(GETDATE() AS DATE)) THEN '>=1 Month & < 6 Months'
    ELSE '<1 Month'
    END AS 'Age_Bracket'
	    ,CASE
		WHEN Date_Type = 'SSD - NO ACCEPTED READ' THEN -1
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -4, CAST(GETDATE() AS DATE)) THEN 7 
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -3, CAST(GETDATE() AS DATE)) THEN 6
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -2, CAST(GETDATE() AS DATE)) THEN 5
		WHEN Accepted_Read_Date <= DATEADD( YEAR, -1, CAST(GETDATE() AS DATE)) THEN 4
	    WHEN Accepted_Read_Date <= DATEADD( m, -6, CAST(GETDATE() AS DATE)) THEN 3 
		WHEN Accepted_Read_Date <= DATEADD( m, -1, CAST(GETDATE() AS DATE)) THEN 2 
    ELSE 1
    END AS 'Bracket_Index'

FROM Results

ORDER BY Accepted_Read_Date ASC;