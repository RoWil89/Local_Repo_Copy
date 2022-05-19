
SELECT TOP 10

	   UNIQ_ID
	   ,J0003 AS 'MPAN'
	  ,[CUSTOMER_PSR_PK]
      ,[CUSTOMER_FK]
      ,[J1699] AS 'Priority Services Category'
      ,[J2209] AS 'PSR code expiry date'
      ,[J0012] AS 'Additional Information'
      ,[PSR_STATUS]

  FROM [AccessReporting].[CUSTOMER].[CUSTOMER_PSR] p

INNER JOIN AccessReporting.CUSTOMER.CUSTOMER C
	on C.CUSTOMER_PK = p.CUSTOMER_FK
INNER JOIN AccessReporting.CUSTOMER.MPAN M
	ON M.UNIQ_ID = C.MPAN_LNK

WHERE UNIQ_ID IN (SELECT MAX(UNIQ_ID)
					FROM AccessReporting.CUSTOMER.MPAN
					GROUP BY J0003) -- Gives most recent regi