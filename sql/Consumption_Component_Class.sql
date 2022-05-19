-- Consumption Component Class IDs
-- Date Created: 2019.02.27
-- Author: Craig Wilkins
-- Description: SQL Code to create a temp table of consumption component class IDs

IF OBJECT_ID('tempdb..#Consumption_Component_Class') IS NOT NULL
	DROP TABLE #Consumption_Component_Class

CREATE TABLE #Consumption_Component_Class

	(
		Consumption_Component_Class_ID INT PRIMARY KEY,
		Measurement_Quantity_ID VARCHAR(2),
		Data_Aggregation_Type VARCHAR(1),
		Metered_Unmetered_Indicator VARCHAR(1),
		Consumption_Component_Indicator VARCHAR(1),
		Actual_Estimated_Indicator VARCHAR(1) NULL,
		AA_EAC_Indicator VARCHAR (1) NULL
	)

	INSERT INTO #Consumption_Component_Class

	( 
	  Consumption_Component_Class_ID
	 ,Measurement_Quantity_ID
	 ,Data_Aggregation_Type
	 ,Metered_Unmetered_Indicator
	 ,Consumption_Component_Indicator
	 ,Actual_Estimated_Indicator
	 ,AA_EAC_Indicator
	 )

	VALUES

		('6', 'AE', 'H', 'M', 'C', 'A', NULL),
		('7', 'AE', 'H', 'M', 'M', 'A', NULL),
		('8', 'AE', 'H', 'M', 'L', 'A', NULL),
		('14', 'AE', 'H', 'M', 'C', 'E', NULL),
		('15', 'AE', 'H', 'M', 'M', 'E', NULL),
		('16', 'AE', 'H', 'M', 'L', 'E', NULL),
		('32', 'AE', 'N', 'M', 'C', NULL, 'E'),
		('33', 'AE', 'N', 'M', 'C', NULL, 'A'),
		('34', 'AE', 'N', 'M', 'L', NULL, 'E'),
		('35', 'AE', 'N', 'M', 'L', NULL, 'A'),
		('36', 'AE', 'H', 'M', 'C', 'A', NULL),
		('37', 'AE', 'H', 'M', 'M', 'A', NULL),
		('38', 'AE', 'H', 'M', 'L', 'A', NULL),
		('39', 'AE', 'H', 'M', 'C', 'E', NULL),
		('40', 'AE', 'H', 'M', 'M', 'E', NULL),
		('41', 'AE', 'H', 'M', 'L', 'E', NULL),
		('48', 'AE', 'H', 'M', 'C', 'A', NULL),
		('49', 'AE', 'H', 'M', 'M', 'A', NULL),
		('50', 'AE', 'H', 'M', 'L', 'A', NULL),
		('51', 'AE', 'H', 'M', 'C', 'E', NULL),
		('52', 'AE', 'H', 'M', 'M', 'E', NULL),
		('53', 'AE', 'H', 'M', 'L', 'E', NULL),
		('60', 'AE', 'H', 'M', 'C', 'A', NULL),
		('61', 'AE', 'H', 'M', 'M', 'A', NULL),
		('62', 'AE', 'H', 'M', 'L', 'A', NULL),
		('63', 'AE', 'H', 'M', 'C', 'E', NULL),
		('64', 'AE', 'H', 'M', 'M', 'E', NULL),
		('65', 'AE', 'H', 'M', 'L', 'E', NULL),
		('1', 'AI', 'H', 'M', 'C', 'A', NULL),
		('2', 'AI', 'H', 'U', 'C', 'A', NULL),
		('3', 'AI', 'H', 'M', 'M', 'A', NULL),
		('4', 'AI', 'H', 'M', 'L', 'A', NULL),
		('5', 'AI', 'H', 'U', 'L', 'A', NULL),
		('9', 'AI', 'H', 'M', 'C', 'E', NULL),
		('10', 'AI', 'H', 'U', 'C', 'E', NULL),
		('11', 'AI', 'H', 'M', 'M', 'E', NULL),
		('12', 'AI', 'H', 'M', 'L', 'E', NULL),
		('13', 'AI', 'H', 'U', 'L', 'E', NULL),
		('17', 'AI', 'N', 'M', 'C', NULL, 'E'),
		('18', 'AI', 'N', 'M', 'C', NULL, 'A'),
		('19', 'AI', 'N', 'U', 'C', NULL, 'E'),
		('20', 'AI', 'N', 'M', 'L', NULL, 'E'),
		('21', 'AI', 'N', 'M', 'L', NULL, 'A'),
		('22', 'AI', 'N', 'U', 'L', NULL, 'E'),
		('23', 'AI', 'H', 'M', 'C', 'A', NULL),
		('25', 'AI', 'H', 'M', 'M', 'A', NULL),
		('26', 'AI', 'H', 'M', 'L', 'A', NULL),
		('28', 'AI', 'H', 'M', 'C', 'E', NULL),
		('30', 'AI', 'H', 'M', 'M', 'E', NULL),
		('31', 'AI', 'H', 'M', 'L', 'E', NULL),
		('42', 'AI', 'H', 'M', 'C', 'A', NULL),
		('43', 'AI', 'H', 'M', 'M', 'A', NULL),
		('44', 'AI', 'H', 'M', 'L', 'A', NULL),
		('45', 'AI', 'H', 'M', 'C', 'E', NULL),
		('46', 'AI', 'H', 'M', 'M', 'E', NULL),
		('47', 'AI', 'H', 'M', 'L', 'E', NULL),
		('54', 'AI', 'H', 'M', 'C', 'A', NULL),
		('55', 'AI', 'H', 'M', 'M', 'A', NULL),
		('56', 'AI', 'H', 'M', 'L', 'A', NULL),
		('57', 'AI', 'H', 'M', 'C', 'E', NULL),
		('58', 'AI', 'H', 'M', 'M', 'E', NULL),
		('59', 'AI', 'H', 'M', 'L', 'E', NULL)

SELECT * FROM #Consumption_Component_Class