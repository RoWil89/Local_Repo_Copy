
-- D0036 SETTLEMENT REPORTING
-- RETRIVES LATEST SETTLED VOLUME FOR ACTIVE IMPORT METERS


USE D0036;

-- SET AND DECLARE VARIABLES

DECLARE @SETDATE DATE
DECLARE @AGDATE DATE

SET @SETDATE = '2018.12.26'
SET @AGDATE =  '2019.01.15'

-- TEMP TABLE CHECK

IF OBJECT_ID('tempdb..#last_read') IS NOT NULL
	DROP TABLE #last_read

IF OBJECT_ID('tempdb..#Act_values') IS NOT NULL
	DROP TABLE #Act_values

IF OBJECT_ID('tempdb..#Est_values') IS NOT NULL
DROP TABLE #Est_values

-- CREATE TEMP LAST READ TABLE (RELATIVE TO THE SETTLEMENT DATE)

SELECT DISTINCT 

	   J0003
	  ,MAX(FlowTstamp) AS 'Max_Read_Date'


into #last_read

FROM D0036.ZHV Z

LEFT JOIN D0036.D0036.G101 G1
ON Z.PK_ZHV = G1.FK_ZHV
LEFT JOIN D0036.D0036.G102 G2
ON G1.PK_101 = G2.FK_101
LEFT JOIN D0036.D0036.G103 G3
ON G2.PK_102 = G3.FK_102

WHERE J0073 = @SETDATE

AND J0103 = 'AI'

AND FlowTstamp < @AGDATE

GROUP BY J0003

-- RETURN DATA FOR MOST RECENT RECORD

SELECT DISTINCT

	 J0073 AS 'Settlement Date'
	,SUM(J0177) AS 'Actual Consumption'

INTO #Act_values

FROM D0036.ZHV Z

LEFT JOIN D0036.D0036.G101 G1
ON 
	Z.PK_ZHV = G1.FK_ZHV
LEFT JOIN D0036.D0036.G102 G2
ON
	 G1.PK_101 = G2.FK_101
LEFT JOIN D0036.D0036.G103 G3
ON 
	G2.PK_102 = G3.FK_102
INNER JOIN #last_read
ON
	G1.J0003 = #last_read.J0003 AND
	FlowTstamp = #last_read.Max_Read_Date

WHERE J0103 = 'AI'

AND J0073 = @SETDATE

AND J0020 = 'A' 

GROUP BY 
	 J0073
	,J0020


SELECT DISTINCT

	 J0073 AS 'Settlement Date'
	,SUM(J0177) AS 'Estimated Consumption'

INTO #Est_values

FROM D0036.ZHV Z

LEFT JOIN D0036.D0036.G101 G1
ON 
	Z.PK_ZHV = G1.FK_ZHV
LEFT JOIN D0036.D0036.G102 G2
ON
	 G1.PK_101 = G2.FK_101
LEFT JOIN D0036.D0036.G103 G3
ON 
	G2.PK_102 = G3.FK_102
INNER JOIN #last_read
ON
	G1.J0003 = #last_read.J0003 AND
	FlowTstamp = #last_read.Max_Read_Date

WHERE J0103 = 'AI'

AND J0073 = @SETDATE

AND J0020 = 'E' 

GROUP BY 
	 J0073
	,J0020


SELECT 

	#Act_values.[Settlement Date]
	,#Act_values.[Actual Consumption]
	,#Est_values.[Estimated Consumption]
	,FORMAT(ROUND(SUM([Actual Consumption]) / (SUM([Actual Consumption])+SUM([Estimated Consumption])),4),'P') AS 'AA%'

FROM #Act_values
	INNER JOIN #Est_values
	 ON #Act_values.[Settlement Date] = #Est_values.[Settlement Date]

GROUP BY

	 #Act_values.[Settlement Date]
	,#Act_values.[Actual Consumption]
	,#Est_values.[Estimated Consumption]
