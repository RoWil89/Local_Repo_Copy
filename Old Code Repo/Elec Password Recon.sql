
SELECT DISTINCT

	 UNIQ_ID
	,J0003 AS 'MPAN'
	,J0049 AS 'EFSD'
	,J0117 AS 'ETSD'
	,J0473 AS 'Disconnection Date'
	,J0693 AS 'Customer Password'
	,J0694 AS 'Password EFD'

  FROM [AFMSLocal].[dbo].[mpan] M

  LEFT JOIN [AFMSLocal].[dbo].[customer] C

  on M.UNIQ_ID = C.MPAN_LNK

WHERE UNIQ_ID IN
(SELECT MAX(UNIQ_ID) FROM AFMSLocal.dbo.mpan GROUP BY J0003)