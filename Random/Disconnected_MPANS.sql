--	Title:		Disconnected MPAN Report
--	Created On: 2020.10.30
--	Purpose:	Identify MPANS which have a populated disconnection date				
--	Author:		Craig Wilkins

SELECT
	
	  J0003 AS 'MPAN'
	 ,J0473 AS 'Disconnection_date'

FROM AFMSLocal.dbo.mpan

WHERE UNIQ_ID IN	(SELECT MAX(UNIQ_ID)
					 FROM AFMSLocal.dbo.mpan
					 GROUP BY J0003)

AND J0473 IS NOT NULL

