 -- =============================================
-- Author:      Kryssy Acock
-- Created date: 15.04.2021
-- Last Updated: 15.04.2021
-- Description: This query runs from AFMS and brings back all MPxNs which we've successfully registered
--				This includes both Domestic and Business Registrations
-- Power Query Name: [UH-Gendb-01] AFMS Gained MPxN [A]
-- =============================================
 

 SELECT DISTINCT [K0533] AS [MPxN]
,[STATUS_CODE_FK] AS [Status Code]
,[K0116] AS 'Supply Start Date'
FROM [AFMSLocal].[gas].[combined_mprn]
WHERE [STATUS_CODE_FK] NOT IN ('3', '7', '19', '22', '30')
--Removing leaked (Rejections, Cancellations and Objection)
--'19' = 'Objected', '22' = 'Objected', '3' = 'Rejected', '7' = 'Cancelled' and '30' = 'Rejected'
--[STATUS_CODE_FK] is the current status of that Registration


Union all

SELECT DISTINCT [J0003] AS [MPxN]
,[X0210] AS [Status Code]
,[J0049] AS 'Supply Start Date'
FROM [AFMSLocal].[dbo].[mpan]
WHERE [X0210] NOT IN ('2', '3', '4', '23', '24')
--Removing leaked (Rejections, Cancellations and Objection)
--'3' = 'Objected', '4' = 'Objected', '24' = 'Cancelled', '23' = 'Cancelled' and '2' = 'Rejected'
--[X0210] is the current status of that Registration