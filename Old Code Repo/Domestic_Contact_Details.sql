
-- NHH Domestic meter points by Last Read date

SELECT
	 C.BP
	,S.MPAN
	,Name1
	,Name2
	,Title
	,First_Name
	,Last_Name
	,S.MC AS 'Measurment_Class'
	,CAST(S.EFSD AS date) AS 'Supply_Start_Date'
	,S.Meter_Type
	,S.Profile_Class
	,S.Total_EAC
	,CAST(S.EAC_EFD AS DATE) AS 'EAC_Effective_From_Data'
	,CAST(S.Dt_Last_Read AS DATE) AS 'Last_Read_Date'
	,BClss
	,E.Email
	,e.Email2
	,e.Phone
	,E.Mobile

FROM D0004.dbo.d0004_weekly_settlement_report S

LEFT JOIN DatSup.DBO.CAMPAN_Data C
	ON S.MPAN = C.MPAN_MPRN

LEFT JOIN DatSup.dbo.Contact_Detail_Ecosystem E
	ON C.BP = E.Business_Partner_ID

WHERE UNIQ_ID IN (	SELECT 
						MAX(UNIQ_ID) AS Max_ID
					FROM D0004.dbo.d0004_weekly_settlement_report
					GROUP BY MPAN
					)

AND ETSD IS NULL -- Is a Live Meter Point
AND Energisation_Sts = 'E' -- Is Energised 
AND Disconnection_Dt is null -- Is Not Disconnected
AND BClss = 'ZDOM' -- Is a dOMESTIC
AND Division = 1 -- Is an Electricity Customer
AND MC = 'A' -- Has a Non Half-Hourly Meter
AND MO_Date = '9999-12-31' -- Is a Live BP

ORDER by Dt_Last_Read

