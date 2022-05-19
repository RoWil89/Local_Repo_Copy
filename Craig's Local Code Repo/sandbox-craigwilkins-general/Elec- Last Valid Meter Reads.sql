/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Title:			Elec - Last Valid Meter Reads
VERSION:		2.0
Author:			Craig Wilkins
Server(s):		uh-gendb-01
Dastabase(s):	AFMSLocal
Date Created:   2021.03.05
Purpose:		To show the last validated read for each live elec MPAN
Sections:	
			01: Create & Populate Read History Table: creates a table of read history at MPAN level
			02: Create & Populate Withdrawn Reads Table: Creates a table of reads that have been withdrawn after being issued
			03: Create & Populate Agent Table: Pulls back most recent agents from AFMS_Local
			04: Create & Populate latest valid EAC table: brings back EAC at a meter reg level - references the appointed agent
			05: Output Results: Use CTE to pull results and enrich with Agent & D0019 (EAC) data


Info:	J number descriptions can be found here: https://dtc.mrasco.com/SearchFlowsByDataItems.aspx

Versions	1.0 - Everything is new!
			2.0	  2021.03.10
				- Added Read History Temp Table
				- Added Withdrawn Reads Temp Table
				- Added Agent Temp Table
				- Added D0019 EAC Temp Table
				- Enhanced Results with Agent data
				- Enhanced Results with TPR level meter reads
				- Enhanced Results with TPR level EACs
				- Updated Section descriptions & version notes

To do:	Max reg etd needs to be null

\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/



/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 1 - Create & Populate Read History Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


IF OBJECT_ID('tempdb..#Read_Hist') IS NOT NULL
    DROP TABLE #Read_Hist

CREATE TABLE #Read_Hist (

	  [ID]											INT IDENTITY (1, 1)	NOT NULL
	 ,[UNIQ_ID]										INT					
	 ,[MPAN]										VARCHAR (13)		NOT NULL
	 ,[Supply Start Date]							DATETIME			NULL
	 ,[MSN]											VARCHAR (10)		NULL
	 ,[Meter Type]									VARCHAR (5)			NULL
	 ,[ETD_MSID]									DATETIME			NULL
	 ,[Energisation Status]							VARCHAR (1)			NULL
	 ,[GSP]											VARCHAR (2)			NULL
	 ,[EAC]											VARCHAR (16)		NULL
	 ,[Meter Reading Reason Code]					VARCHAR (2)			NULL
	 ,[TPR]											VARCHAR	(5)			NULL
	 ,[Reading Date]								DATE				NULL
	 ,[BSC Validation Status]						VARCHAR	(1)			NULL
	 ,[Reading Type]								VARCHAR (1)			NULL
	 ,[Register Reading]							FLOAT				NULL
	 ,[FLOW_RECEIVED]								VARCHAR (15)		NULL
	 ,[DATE_RECEIVED]								DATETIME			NULL
	 ,[READ_KEY]									VARCHAR (100)
	 ,[Sig_Date]									DATETIME
);


INSERT INTO #Read_Hist

(
	  [UNIQ_ID]										
	 ,[MPAN]
	 ,[Supply Start Date]
	 ,[MSN]											
	 ,[Meter Type]									
	 ,[ETD_MSID]
	 ,[Energisation Status]
	 ,[GSP]											
	 ,[EAC]											
	 ,[Meter Reading Reason Code]					
	 ,[TPR]											
	 ,[Reading Date]								
	 ,[BSC Validation Status]						
	 ,[Reading Type]								
	 ,[Register Reading]							
	 ,[FLOW_RECEIVED]								
	 ,[DATE_RECEIVED]
	 ,[READ_KEY]
	 ,[Sig_Date]
)

SELECT

	 M.UNIQ_ID
	,M.J0003 AS 'MPAN'
	,M.J0049 AS 'Supply Start Date'
	,ME.J0004 AS 'MSN'
	,ME.J0483 AS 'Meter Type'
	,ME.ETD_MSID
	,M.J0080 AS 'Energisation Status'
	,M.J0066 AS 'GSP'
	,M.J0081 AS 'EAC'
	,MRR.J0332 AS 'Meter Reading Reason Code'
	,MR.J0078 AS 'TPR'
	,CAST(MRR.J0016 AS DATE) AS 'Reading Date'
	,MRR.J0022 AS 'BSC Validation Status'
	,MRR.J0171 AS 'Reading Type'
	,MRR.J0040 AS 'Register Reading'
	,MRR.FLOW_RECEIVED
	,MRR.DATE_RECEIVED
	,CONCAT(M.J0003,'_',ME.J0004,'_',MR.J0078,'_',MRR.J0016,'_',MRR.J0040) AS 'Read_Key' -- Needed to remove validated reads which have been withdrawn
	,CASE
		WHEN J0117 IS NULL THEN GETDATE() -- Used for the EAC calcs from the D0019 data, when a supply is live then use today, else use the loss date
		ELSE J0117
	 END AS 'Sig_Date'

FROM AFMSLocal.dbo.mpan M

INNER JOIN AFMSLocal.dbo.meter ME
ON M.UNIQ_ID = ME.MPAN_LNK
		AND ME.METER_PK IN (SELECT MAX(METER_PK) -- Is the maximum meter
							FROM AFMSLocal.dbo.meter
							GROUP BY MPAN_LNK)

INNER JOIN AFMSLocal.dbo.meter_register MR
ON ME.METER_PK = MR.METER_FK
AND MR.J0103 = 'AI' -- the register type is active import (needed to exclude non-settlement registers)

INNER JOIN AFMSLocal.dbo.meter_reg_reading MRR
ON MR.METER_REG_PK = MRR.METER_REG_FK 
AND MRR.J0016 BETWEEN '2010.01.01' AND GETDATE() -- in a set date range
AND MRR.FLOW_RECEIVED IN ('D0010', 'D0086') -- is a meter read flow

WHERE M.UNIQ_ID IN (SELECT max(UNIQ_ID)
FROM AFMSLocal.dbo.mpan
GROUP BY J0003)

AND M.J0082 = 'A' -- is NHH 

AND M.J0117 IS NULL -- is not a lost account

AND M.J0473 IS NULL --Is not Disconnected;

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 2 - Create & Populate Withdrawn Reads Table
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


IF OBJECT_ID('tempdb..#Withdrawn') IS NOT NULL
    DROP TABLE #Withdrawn

CREATE TABLE #Withdrawn (

	  [ID]											INT IDENTITY (1, 1)	NOT NULL
	 ,[MPAN]										VARCHAR (13)		NOT NULL
	 ,[READ_KEY]									VARCHAR (100)
	 ,[DATE_RECEIVED]								DATETIME			NULL		
);

INSERT INTO #Read_Hist

(									
	  [MPAN]										
	 ,[READ_KEY]						
	 ,[DATE_RECEIVED]
)

SELECT

  MPAN
 ,Read_Key
 ,DATE_RECEIVED

FROM #Read_Hist

WHERE [Reading Type] = 'W';


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 3 - Create Agent Table: Pull back most recent agents from AFMS_Local
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#Agents') IS NOT NULL
    DROP TABLE #Agents

CREATE TABLE #Agents (

	  [ID]											INT IDENTITY (1, 1)	NOT NULL
	 ,[UNIQ_ID]										INT					NULL
	 ,[MPAN]										VARCHAR (13)		NOT NULL
	 ,[EFSD_REGI]									DATETIME			NULL
	 ,[ETSD_REGI]									DATETIME			NULL
	 ,[MOP]											VARCHAR (4)			NULL
	 ,[DA]											VARCHAR (4)			NULL
	 ,[DC]											VARCHAR (4)			NULL
		
);

INSERT INTO #Agents

(									
	  [UNIQ_ID]										
	 ,[MPAN]										
	 ,[EFSD_REGI]									
	 ,[ETSD_REGI]									
	 ,[MOP]
	 ,[DA]
	 ,[DC]
)


SELECT

	 UNIQ_ID
	,J0003
	,J0049 AS 'EFSD_REGI'
	,J0117 AS 'ETSD_REGI'
	,J0178 AS 'MOP'
	,J0183 AS 'DA'
	,J0205 AS 'DC'
	
FROM [AFMSLocal].[dbo].[mpan] M

LEFT JOIN [AFMSLocal].[dbo].[agent] A
	ON M.UNIQ_ID = A.MPAN_LNK

WHERE UNIQ_ID IN ( SELECT UNIQ_ID FROM #Read_Hist);

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 4 - Create & Populate latest valid EAC table - brings back EAC at a meter reg level
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

IF OBJECT_ID('tempdb..#Latest_Valid_EAC') IS NOT NULL
    DROP TABLE #Latest_Valid_EAC

CREATE TABLE #Latest_Valid_EAC (

		 [ID]										INT IDENTITY (1, 1)	NOT NULL
		,[archdir_dt]								DATE				NOT NULL
		,[MPAN]										VARCHAR (13)		NOT NULL
		,[EAC_EFD]									DATE				NULL
		,[EAC_CHECKSUM]								CHAR(5)				NULL
		,[EAC]										NUMERIC (14,1)		NULL
		
);

INSERT INTO #Latest_Valid_EAC

(									
		 [archdir_dt]
		,[MPAN]										
		,[EAC_EFD]
		,[EAC_CHECKSUM]
		,[EAC]
)


SELECT DISTINCT

       [archdir_dt]
      ,C.[J0003] AS 'MPAN'
      ,[j1096_ea] AS 'EAC_EFD'
      ,[j0078_ea] AS 'EAC_CHECKSUM'
      ,C.[j0081] AS 'EAC'

  FROM [D0019].[dbo].[ConsolidatedD0019s] C

  LEFT JOIN #Agents on c.from_id = #Agents.DC and c.J0003 = #Agents.MPAN

  INNER JOIN #Read_Hist on C.J0003 = #Read_Hist.MPAN AND C.flow_tstamp between #Read_Hist.[Supply Start Date] AND #Read_Hist.[Sig_Date]
	
  WHERE j1096_ea IS NOT NULL

  AND CAST(CONCAT([J0109],'_',[j1096_ea]) AS varchar) IN 
					(	SELECT
						CAST(CONCAT(MAX([J0109]),'_',MAX([j1096_ea])) AS varchar)
					FROM [D0019].[dbo].[ConsolidatedD0019s] C
					LEFT JOIN #Agents on #Agents.DC = C.from_id AND #Agents.MPAN = C.J0003
					WHERE j1096_ea IS NOT NULL
					AND DC IS NOT NULL
					AND [j0078_ea] IS NOT NULL 
					GROUP BY C.J0003, DC
					)

  AND C.j0084 = 'ECOT'

  ORDER BY archdir_dt desc;

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
Section 5 - Output Results
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/


WITH LatestValidRead AS
(
SELECT
	 UNIQ_ID
	,#Read_Hist.MPAN
	,#Read_Hist.[Supply Start Date]
	,MSN
	,[Meter Type]
	,ETD_MSID
	,[Energisation Status]
	,GSP
	,EAC
	,[Meter Reading Reason Code]
	,TPR
	,[Reading Date]
	,[BSC Validation Status]
	,[Reading Type]
	,[Register Reading]
	,FLOW_RECEIVED
	,#Read_Hist.DATE_RECEIVED
	,ROW_NUMBER() OVER(PARTITION BY #Read_Hist.MPAN, TPR
						ORDER BY #Read_Hist.MPAN, TPR, [Reading Date] DESC) AS 'RN'

FROM #Read_Hist
	LEFT  JOIN #Withdrawn
		ON #Read_Hist.Read_Key = #Withdrawn.Read_Key
WHERE (#Withdrawn.Read_Key IS NULL or #Read_Hist.DATE_RECEIVED > #Withdrawn.DATE_RECEIVED)
AND [BSC Validation Status] = 'V'
AND [Reading Type] <> 'W'
)

SELECT

	 LatestValidRead.MPAN
	, CAST([Supply Start Date] AS DATE) AS 'Supply Start Date'
	,MSN
	,[Meter Type]
	,ETD_MSID
	,[Energisation Status]
	,GSP
	,[Meter Reading Reason Code]
	,TPR
	,[Reading Date]
	,[BSC Validation Status]
	,[Reading Type]
	,[Register Reading]
	,FLOW_RECEIVED
	,DATE_RECEIVED

	,CASE 
			WHEN [Reading Date] <= DATEADD( m, -14, CAST(GETDATE() AS DATE)) THEN '>=14 MONTHS'
			WHEN [Reading Date] <= DATEADD( m, -6, CAST(GETDATE() AS DATE)) THEN '>=6 & <14 MONTHS'
			WHEN [Reading Date] <= DATEADD( m, -3, CAST(GETDATE() AS DATE)) THEN '>=3 & <6 MONTHS'
			WHEN [Reading Date] <= DATEADD( m, -1, CAST(GETDATE() AS DATE)) THEN '>=1 & <3 MONTHS'
			WHEN [Reading Date] <= DATEADD( d, -7, CAST(GETDATE() AS DATE)) THEN '>=1 WEEK & <1 MONTH'
			ELSE '<1 WEEK'
	END AS 'Bracket'

	,CASE	
			WHEN [Reading Date] <= DATEADD( m, -14, CAST(GETDATE() AS DATE)) THEN '6'
			WHEN [Reading Date] <= DATEADD( m, -6, CAST(GETDATE() AS DATE)) THEN '5'
			WHEN [Reading Date] <= DATEADD( m, -3, CAST(GETDATE() AS DATE)) THEN '4'
			WHEN [Reading Date] <= DATEADD( m, -1, CAST(GETDATE() AS DATE)) THEN '3'
			WHEN [Reading Date] <= DATEADD( d, -7, CAST(GETDATE() AS DATE)) THEN '2'
			ELSE '1'
	 END AS 'Bracket Index'
	 , MOP
	 , DA
	 , DC
	 ,#Latest_Valid_EAC.EAC AS 'Register EAC'
	 ,#Latest_Valid_EAC.EAC_EFD

FROM LatestValidRead

LEFT JOIN #Agents
	ON LatestValidRead.UNIQ_ID = #Agents.UNIQ_ID
LEFT JOIN #Latest_Valid_EAC
	ON LatestValidRead.MPAN =  #Latest_Valid_EAC.MPAN AND LatestValidRead.TPR = #Latest_Valid_EAC.EAC_CHECKSUM


WHERE RN = '1'


ORDER BY [Reading Date] DESC, LatestValidRead.MPAN, LatestValidRead.TPR