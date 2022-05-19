

FROM [D0004].[dbo].[d0004_file]

INNER JOIN dbo.d0004_014

	ON dbo.d0004_file.PK_File = dbo.d0004_014.FK_File

INNER JOIN dbo.d0004_015

	ON dbo.d0004_014.PK_014 = dbo.d0004_015.FK_014

INNER JOIN dbo.d0004_016

	ON dbo.d0004_015.PK_015 = dbo.d0004_016.FK_015

LEFT JOIN d0004_Status_SETT

	ON d0004_Status_SETT.FK_014 = dbo.d0004_014.PK_014