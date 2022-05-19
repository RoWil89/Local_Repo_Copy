
-- create Name table

IF OBJECT_ID('tempdb..#Group_Names') IS NOT NULL
	DROP TABLE #Group_Names

CREATE TABLE #Group_Names (Group_Name varchar(50))

INSERT INTO #Group_Names (Group_Name) VALUES

('Hanover Housing'),
('Mainstay'),
('Mainstay Commercial'),
('Rendall and Rittner'),
('Rendall and Rittner Regional');

-- Get MPANS from pricing table

IF OBJECT_ID('tempdb..#FP_MPANS1') IS NOT NULL
	DROP TABLE #FP_MPANS1

SELECT   Group_name
		,m.Mpan

		INTO #FP_MPANS1
      
FROM [FixedPricing].[fixed_p].[Mpan_detail_records] m
     INNER JOIN FixedPricing.fixed_p.Quote_details q ON m.Grouping_id = q.Grouping_ID
                                                        AND q.Quote_id = m.Quote_id
     WHERE q.Accepted_flag = 'Y'
      AND Contract_end_date >= getdate()
	  AND Group_name IN (SELECT * FROM #Group_Names)

ORDER BY Group_name;

-- Get MPRNS from pricing table

IF OBJECT_ID('tempdb..#FP_MPANS2') IS NOT NULL
	DROP TABLE #FP_MPANS2

SELECT Company
       ,m.MPRN

	   INTO #FP_MPANS2

FROM FixedPricing.fixed_g.Quote_details q
     INNER JOIN FixedPricing.fixed_g.MPRN_Details m ON q.Unique_ID = m.Unique_ID
     
WHERE  q.Accepted_Flag = 'Y'
AND q.CED >= getdate()
AND Company IN (SELECT * FROM #Group_Names)
ORDER BY Company;

--GET DATA FROM CAPE

IF OBJECT_ID('tempdb..#CAPE_MPANS') IS NOT NULL
	DROP TABLE #CAPE_MPANS


SELECT TenderAlias, 
       r.Mpan

	   INTO #CAPE_MPANS

FROM [CAPE].[dbo].FixedQuotes_StructureSiteList l
     INNER JOIN [CAPE].dbo.FixedQuotes_Structures s ON l.StructureID = s.StructureID
     INNER JOIN CAPE.dbo.FixedQuotes_QuoteRequest q ON s.StructureID = q.StructureId
                                                       AND q.StructureId = l.StructureID
     INNER JOIN CAPE.dbo.FixedQuotes_QuoteRates r ON q.QuoteID = r.QuoteID
                                                     AND r.Mpan = l.Mpan
     INNER JOIN cape.dbo.FixedQuotes_Tenders t ON t.TenderID = s.TenderID
WHERE q.AcceptedAt >= '2019-05-01'
and ED > getdate()
and TenderAlias IN (SELECT * FROM #Group_Names)
ORDER BY TenderAlias;

-- UNION DATA INTO SEPERATE TABLE

IF OBJECT_ID('tempdb..#Company_MPXNs') IS NOT NULL
	DROP TABLE #Company_MPXNs

SELECT

	 Group_name AS 'Company'
	,Mpan AS 'MPXN'

	INTO #Company_MPXNs

FROM #FP_MPANS1

UNION

SELECT

	Company AS 'Company'
	,MPRN AS 'MPXN'

FROM #FP_MPANS2

UNION

SELECT

	TenderAlias AS 'Company'
	,Mpan AS 'MPXN'

FROM #CAPE_MPANS;

-- SELECT SETTLEMENT DATA PER MPAN
SELECT
	
	Company
	,MPXN
	,GSP_Grp
	,MC
	,EFSD
	,ETSD
	,Meter_Type
	,Energisation_Sts
	,Total_EAC
	,Dt_Last_Read

FROM #Company_MPXNs C

INNER JOIN [UH-GENDB-01].D0004.dbo.d0004_weekly_settlement_report S

ON C.MPXN = S.MPAN

WHERE UNIQ_ID IN (	SELECT MAX(UNIQ_ID)
					FROM [UH-GENDB-01].D0004.dbo.d0004_weekly_settlement_report
					GROUP BY MPAN)