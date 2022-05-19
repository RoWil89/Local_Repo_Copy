  /*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title: Electricity EAC Report
VERSION: 0.1
Author: Craig Wilkins
Date Created: 2021.02.18
Purpose: To create a view of NHH EAC Values 

Sections:	1:	Declare variables & drop temp tables if they exist
			2:	Create Read History Table
					-Read history table at a TPR level returns over 3.5 million rows
			3:	Return Results

TO DO:		Import / Export Indicator
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Drop Temp Tables
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


IF OBJECT_ID('tempdb..#Agents') IS NOT NULL
    DROP TABLE #Agents

IF OBJECT_ID('tempdb..#Latest_Valid_EAC') IS NOT NULL
    DROP TABLE #Latest_Valid_EAC

IF OBJECT_ID('tempdb..#TPR_EAC') IS NOT NULL
    DROP TABLE #TPR_EAC

IF OBJECT_ID('tempdb..#LiveMPANS') IS NOT NULL
    DROP TABLE #LiveMPANS


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Create Live MPAN Temp Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT 
	 UNIQ_ID
	,J0003
	,J0080 AS 'Energisation Status'
	,J0081
	,J0049 AS 'Start_Date'
	,J0117 AS 'Loss_Date'
	,CASE
		WHEN J0117 IS NULL THEN GETDATE()
		ELSE J0117
	 END AS 'Sig_Date'

	INTO #LiveMPANS

	FROM AFMSLocal.dbo.mpan

	WHERE UNIQ_ID IN (	SELECT
							MAX(UNIQ_ID)
						FROM AFMSLocal.dbo.mpan 
						GROUP BY J0003
					 ) -- Is for the latest regi
	AND J0473 IS NULL -- Is not disconnected
	AND (J0117 >= GETDATE() or J0117 IS NULL) -- Is on supply
	AND J0080 = 'E' -- Is Energised
	AND J0082 = 'A' -- Is Non Half-Hourly

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Create Agent Table: Pull back most recent agents from AFMS_Local for Live MPANS
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT

	UNIQ_ID
	,J0003
	,J0049 AS 'EFSD_REGI'
	,J0117 AS 'ETSD_REGI'
	,J0178 AS 'MOP'
	,J0183 AS 'DA'
	,J0205 AS 'DC'

INTO #Agents
	
FROM [AFMSLocal].[dbo].[mpan] M

LEFT JOIN [AFMSLocal].[dbo].[agent] A
	ON M.UNIQ_ID = A.MPAN_LNK

WHERE UNIQ_ID IN ( SELECT UNIQ_ID FROM #LiveMPANS)

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Temp Table Test
/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
-- SELECT TOP 10 * FROM #Agents

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Create latest EAC table - brings back EAC at a meter reg level
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

SELECT DISTINCT

       [archdir_dt]
      ,C.[J0003] AS 'MPAN'
      ,[j1096_ea] AS 'EAC_EFD'
      ,[j0078_ea] AS 'EAC_CHECKSUM'
      ,C.[j0081] AS 'EAC'

/* Removed as not needed in main query
		[filename]
		,[file_id]
		,[flow_type]
		,[from_id]
		,[flow_tstamp]
		,[pk_d0019_zin]
		,[J0109] AS 'Instruction_Number'
		,[J1109] AS 'Type_Code'
		,[j1096_reg] AS 'EFSD_REGI'
		,C.[j0084] AS 'Supplier_ID'
		,[j1096_psc] AS 'EFSD_PC'
		,C.[j0071] AS 'Profile Class Id'
		,C.[j0076] AS 'Standard Settlement Configuration Id'
		,[j1096_mc] AS 'EFSD_MC'
		,C.[j0082] AS 'Measurement Class Id'
		,[j1096_gsp] AS 'EFSD_GSP'
		,C.[j0066] AS 'GSP'
		,[j1096_es] AS 'EFSD_Energisation Status Id'
		,[j1099] AS 'Energisation Status Id'
		,[pk_d0019_ead]
		,[pk_d0019_eah]
		,DC
		,#LiveMPANS.[Start_Date]
		,#LiveMPANS.[Loss_Date]
*/

  INTO #Latest_Valid_EAC 

  FROM [D0019].[dbo].[ConsolidatedD0019s] C

  LEFT JOIN #Agents on c.from_id = #Agents.DC and c.J0003 = #Agents.J0003

  INNER JOIN #LiveMPANS on C.J0003 = #LiveMPANS.J0003 AND C.flow_tstamp between #LiveMPANS.[Start_Date] AND #LiveMPANS.[Sig_Date]
	

  WHERE j1096_ea IS NOT NULL

  AND CAST(CONCAT([J0109],'_',[j1096_ea]) AS varchar) IN 
					(	SELECT
						CAST(CONCAT(MAX([J0109]),'_',MAX([j1096_ea])) AS varchar)
					FROM [D0019].[dbo].[ConsolidatedD0019s] C
					LEFT JOIN #Agents on #Agents.DC = C.from_id AND #Agents.J0003 = C.J0003
					WHERE j1096_ea IS NOT NULL
					AND DC IS NOT NULL
					AND [j0078_ea] IS NOT NULL 
					GROUP BY C.J0003, DC
					)

  AND C.j0084 = 'ECOT'

  ORDER BY archdir_dt desc

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Temp Table Test
/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

  --SELECT TOP 10 * FROM #Latest_Valid_EAC

 /*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - SELECT DATA FROM TEMP TABLE into a ranked table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

  SELECT DISTINCT
  
	 MPAN
	,EAC_EFD
	,EAC_CHECKSUM AS 'TPR'
	,EAC AS 'EAC'
	,DENSE_RANK() OVER (PARTITION BY MPAN ORDER BY EAC_CHECKSUM ASC) AS 'Rank'

  INTO #TPR_EAC
  
  FROM #Latest_Valid_EAC

  WHERE EAC_CHECKSUM IS NOT NULL

  ORDER BY MPAN, TPR;


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Temp Table Test
/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

 --select * from #TPR_EAC;

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section x - Return data using Pivot & CTE
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


  WITH CTE
  AS
  (

  SELECT

	MPAN AS 'MPAN'
	,EAC_EFD
	,[1] AS 'Reg_1'
	,[2] AS 'Reg_2'
	,[3] AS 'Reg_3'
	,[4] AS 'Reg_4'
	,[5] AS 'Reg_5'
	,[6] AS 'Reg_6'


  FROM #TPR_EAC
  PIVOT
  (

  SUM(EAC)
  FOR [RANK]
  IN ([1],[2],[3],[4],[5],[6])
  ) AS EAC_PIVOT

  )

  SELECT
	
	MPAN
	,CAST(MAX(EAC_EFD) AS DATE) AS 'EAC_EFD'
	,MAX(Reg_1) AS 'Reg_1 '
	,MAX(Reg_2) AS 'Reg_2'
	,MAX(Reg_3) AS 'Reg_3'
	,MAX(Reg_4) AS 'Reg_4'
	,MAX(Reg_5) AS 'Reg_5'
	,MAX(Reg_6) AS 'Reg_6'
	,CASE
		WHEN MAX(Reg_2)IS NULL THEN SUM(Reg_1)
		WHEN MAX(Reg_3) IS NULL THEN SUM(Reg_1) + SUM(Reg_2)
		WHEN MAX(Reg_4) IS NULL THEN SUM(Reg_1) + SUM(Reg_2) + SUM(Reg_3)
		WHEN MAX(Reg_5) IS NULL THEN SUM(Reg_1) + SUM(Reg_2) + SUM(Reg_3) + SUM(Reg_4)
		WHEN MAX(Reg_6)IS NULL THEN SUM(Reg_1) + SUM(Reg_2) + SUM(Reg_3) + SUM(Reg_4) + SUM(Reg_5)
		ELSE SUM(Reg_1) + SUM(Reg_2) + SUM(Reg_3) + SUM(Reg_4) + SUM(Reg_5) + SUM(Reg_6)
	END AS 'Total_EAC'
	

  FROM CTE

  WHERE MPAN IN (SELECT J0003 FROM #LiveMPANS)

  GROUP BY MPAN

  ORDER BY EAC_EFD ASC