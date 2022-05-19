USE D0019

SELECT DISTINCT

	   [filename]
      ,[archdir_dt]
      ,[file_id]
      ,[flow_type]
      ,[from_id]
      ,[flow_tstamp]
      ,[pk_d0019_zin]
      ,[J0109] AS 'Instruction_Number'
      ,[J1109] AS 'Type_Code'
      ,C.[J0003] AS 'MPAN'
      ,[j1096_ea] AS 'EAC_EFD'
      ,[j0078_ea] AS 'EAC_CHECKSUM'
      ,C.[j0081] AS 'EAC'
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
  FROM [D0019].[dbo].[ConsolidatedD0019s] C

  WHERE j1096_ea IS NOT NULL

  AND [J0109] IN (	SELECT
						MAX([J0109])
					FROM [D0019].[dbo].[ConsolidatedD0019s]
					WHERE j1096_ea IS NOT NULL
					GROUP BY J0003
				 )
  AND CONCAT(j1096_ea,'_',C.J0003) IN ( SELECT CONCAT(MAX(j1096_ea),'_',J0003)  FROM ConsolidatedD0019s where j1096_ea IS NOT NULL GROUP BY J0003)

  AND C.j0084 = 'ECOT'

  order by archdir_dt desc