
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title: D0081 Report - Overall HH AA% Performance by Date
VERSION: 1
Author: Craig Wilkins
Date Created: 2019.04.25
Purpose: To create a view of HH settlement performance by date

Sections:	1:	Declare and set variables
			2:	Drop & Create temp tables
			3:	Populate #Estimated_Energy temp table
			4:  Populate #Actual_Energy temp table
			5:	Return data from temp tables

\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

USE D0081;

SET NOCOUNT ON;

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 1 - Declare and set variables
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

DECLARE @RunTypeVal CHAR(2)

SET @RunTypeVal = 'SF'

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 2 - Drop & Create temp tables
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#Estimated_Energy') IS NOT NULL
	DROP TABLE #Estimated_Energy

CREATE TABLE #Estimated_Energy (
	 [ID]											INT IDENTITY(1, 1) NOT NULL
	,[Settlement Date]								DATE NOT NULL
	,[Run_Date]										DATE NULL
	,[Settlement Run]								CHAR (2) NOT NULL
	,[GSP]											CHAR (2) NOT NULL
	,[Actual/Estimated Indicator]					CHAR (1) NOT NULL
	,[Daily CCC Aggregated Supplier Consumption]	NUMERIC(13,3) NULL
);

IF OBJECT_ID('tempdb..#Actual_Energy') IS NOT NULL
	DROP TABLE #Actual_Energy

CREATE TABLE #Actual_Energy (
	 [ID]											INT IDENTITY(1, 1) NOT NULL
	,[Settlement Date]								DATE NOT NULL
	,[Run_Date]										DATE NULL
	,[Settlement Run]								CHAR (2) NOT NULL
	,[GSP]											CHAR (2) NOT NULL
	,[Actual/Estimated Indicator]					CHAR (1) NOT NULL
	,[Daily CCC Aggregated Supplier Consumption]	NUMERIC(13,3) NULL
);

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 3 - Populate #Estimated_Energy temp table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

INSERT INTO #Estimated_Energy
(
	 [Settlement Date]
	,[Run_Date]
	,[Settlement Run]
	,[GSP]
	,[Actual/Estimated Indicator]
	,[Daily CCC Aggregated Supplier Consumption]
)

SELECT

	 ZP.J0073 AS 'Settlement Date'
	,H.J0195 AS 'Run_Date' 
	,ZP.J0146 AS 'Settlement Run'
	,G.J0066 AS 'GSP'
	,C.J0020 AS 'Actual/Estimated Indicator'
	,T.J0894 AS 'Daily CCC Aggregated Supplier Consumption'

FROM D0081.D0081.ZHV ZH

	JOIN D0081.D0081.ZPD ZP
			ON ZH.PK_ZHV = ZP.FK_ZHV
	JOIN D0081.D0081.HDR H
			ON ZH.PK_ZHV = H.FK_ZHV
	JOIN D0081.D0081.GSP G
			ON ZH.PK_ZHV = G.FK_ZHV
	JOIN D0081.D0081.CCC C
			ON G.PK_GSP = C.FK_GSP
	JOIN D0081.D0081.TOT T
			ON C.PK_CCC = T.FK_CCC

WHERE	J0103 = 'AI'
AND		J0163 = 'H'
AND		J0164 = 'M'
AND		J0162 =	'C'
AND		J0160 IN ('1','9')
AND		J0020 = 'E'
AND ZP.J0146 = @RunTypeVal;

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 4 - Populate #Actual_Energy temp table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

INSERT INTO #Actual_Energy
(
	 [Settlement Date]
	,[Run_Date]
	,[Settlement Run]
	,[GSP]
	,[Actual/Estimated Indicator]
	,[Daily CCC Aggregated Supplier Consumption]
)


SELECT

	 ZP.J0073 AS 'Settlement Date'
	,H.J0195 AS 'Run_Date' 
	,ZP.J0146 AS 'Settlement Run'
	,G.J0066 AS 'GSP'
	,C.J0020 AS 'Actual/Estimated Indicator'
	,T.J0894 AS 'Daily CCC Aggregated Supplier Consumption'

FROM D0081.D0081.ZHV ZH

	JOIN D0081.D0081.ZPD ZP
			ON ZH.PK_ZHV = ZP.FK_ZHV
	JOIN D0081.D0081.HDR H
			ON ZH.PK_ZHV = H.FK_ZHV
	JOIN D0081.D0081.GSP G
			ON ZH.PK_ZHV = G.FK_ZHV
	JOIN D0081.D0081.CCC C
			ON G.PK_GSP = C.FK_GSP
	JOIN D0081.D0081.TOT T
			ON C.PK_CCC = T.FK_CCC


WHERE	J0103 = 'AI'
AND		J0163 = 'H'
AND		J0164 = 'M'
AND		J0162 =	'C'
AND		J0160 IN ('1','9')
AND		J0020 = 'A'
AND ZP.J0146 = @RunTypeVal

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 5 - Return data from temp tables
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#Results') IS NOT NULL
	DROP TABLE #Results

SELECT

	 A.[Settlement Date]
	,A.[Run_Date]
	,A.[Settlement Run]
	,A.GSP
	,CAST(ROUND(SUM(A.[Daily CCC Aggregated Supplier Consumption]), 2) AS decimal(16,2)) AS 'Actual Energy'
	,CAST(ROUND(SUM(E.[Daily CCC Aggregated Supplier Consumption]), 2) AS decimal(16,2)) AS 'Estimated Energy'
	,CAST(ROUND(SUM(A.[Daily CCC Aggregated Supplier Consumption]) + SUM(E.[Daily CCC Aggregated Supplier Consumption]), 2) AS decimal(16,2)) AS 'Total Energy'
	,CASE 
		WHEN SUM(e.[Daily CCC Aggregated Supplier Consumption]) is null THEN FORMAT(ROUND(SUM(A.[Daily CCC Aggregated Supplier Consumption]) / (SUM(A.[Daily CCC Aggregated Supplier Consumption])), 4), 'P') 
		ELSE FORMAT(ROUND(SUM(A.[Daily CCC Aggregated Supplier Consumption]) / (SUM(A.[Daily CCC Aggregated Supplier Consumption]) + SUM(E.[Daily CCC Aggregated Supplier Consumption])), 4), 'P')
		END AS 'AA%'	

INTO #Results

FROM #Actual_Energy A

LEFT JOIN #Estimated_Energy E

ON A.[Settlement Date] = E.[Settlement Date] AND A.GSP = E.GSP AND A.[Settlement Run] = E.[Settlement Run]

GROUP BY A.[Settlement Date], A.[Run_Date], A.[Settlement Run], a.GSP

ORDER by [Settlement Date] ASC, a.GSP ASC

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 6 - Return GSP by Month
			This section is used to return the first data point per month
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT
	 Max([Settlement Date]) AS 'Settlement_Date'
	,[Run_Date]
	,DATEADD(DAY,1,EOMONTH([Run_Date], -1)) AS 'Month_Start'
	,[Settlement Run]
	,GSP
	,[Actual Energy]
	,[Estimated Energy]
	,[Total Energy]
	,[AA%]

FROM #Results

WHERE Run_Date IN  (SELECT MIN(Run_Date)
					FROM #Results
					GROUP BY EOMONTH([Run_Date]))

GROUP BY [Run_Date], [Settlement Run], GSP, [Actual Energy], [Estimated Energy], [Total Energy], [AA%]
ORDER BY Run_Date ASC