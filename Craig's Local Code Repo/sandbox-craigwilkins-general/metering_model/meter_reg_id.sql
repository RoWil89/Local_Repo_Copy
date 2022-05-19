-- Databricks notebook source
-- MAGIC %md
-- MAGIC 
-- MAGIC #Meter Reg ID report
-- MAGIC 
-- MAGIC  The purpose of this report is to identify the reg IDs for each MPAN

-- COMMAND ----------

-- DBTITLE 1,Tables and Joins
SELECT * FROM customer.mpan AS M
LEFT JOIN customer.meter AS ME
  ON M.UNIQ_ID = ME.MPAN_LNK
LEFT JOIN customer.meter_register AS MR
  ON ME.METER_PK = MR.METER_FK

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC ## Live Meters
-- MAGIC 
-- MAGIC 
-- MAGIC - A meter is considered live where the etd_msid is null
-- MAGIC - The latest meter is the max meter pk by mpan_lnk

-- COMMAND ----------

-- DBTITLE 1,Get Live Meters
CREATE OR REPLACE TEMP VIEW elec_meter AS
(
SELECT
   ME.mpan_lnk
  ,max(ME.meter_pk) AS meter_pk
FROM
  customer.meter ME
WHERE
  ME.etd_msid is null
GROUP BY ME.mpan_lnk
);

SELECT * FROM elec_meter LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC ## Create meter_reg_id temp table
-- MAGIC 
-- MAGIC - The latest registration period is the max uniq_id by j0003 (MPAN)
-- MAGIC - An MPAN is live where J0473 (disconnection date) is null AND;
-- MAGIC - Where J117 (supply end date) is null or in the future AND;
-- MAGIC - Where J0049 (Supply Start Date) is before or including today

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW meter_reg_id AS
(
SELECT DISTINCT

   M.J0003 AS MPAN
  ,ME.J0004 AS MSN
  ,ME.J0848 AS meter_install_date
  ,ME.J1254 AS EFSD_MSMTD
  ,ME.J1269 AS meter_removal_date
  ,MR.J0010 AS meter_register_id
  ,MR.EFD_ID
  ,MR.ETD_ID
  ,MR.J0078 AS TPR
  ,MR.J0103 AS measurement_quantity_id
  

FROM customer.mpan AS M
LEFT JOIN customer.meter AS ME
  ON M.UNIQ_ID = ME.MPAN_LNK
LEFT JOIN elec_meter EM
  ON ME.meter_pk = EM.meter_pk
LEFT JOIN customer.meter_register AS MR
  ON ME.METER_PK = MR.METER_FK  
                      
-- Select only the most up to date registration period for the MPAN

WHERE UNIQ_ID IN (SELECT
                  MAX(UNIQ_ID)
                FROM customer.mpan
                GROUP BY J0003)
                
  AND M.J0049 <= CURRENT_DATE() -- Supply_startdate is before today
  AND (M.J0117 >= CURRENT_DATE() OR M.j0117 is NULL) -- Supply_enddate is after today or supply_enddate is null
  AND M.J0473 is NULL -- Disconnection_date is null
                
ORDER BY MPAN, MSN, meter_register_id ASC
);

SELECT * FROM meter_reg_id;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC ## Create and Populate metering_reporting.meter_reg_id table

-- COMMAND ----------

DESCRIBE meter_reg_id;

-- COMMAND ----------

-- drop table if exists metering_reporting.meter_reg_id;
CREATE TABLE IF NOT EXISTS metering_reporting.meter_reg_id (	
MPAN string,
MSN	string,
meter_install_date	timestamp,
EFSD_MSMTD	timestamp,
meter_removal_date	timestamp,
meter_register_id	string,
EFD_ID timestamp,
ETD_ID timestamp,
TPR	string,
measurement_quantity_id	string
)
USING DELTA;

-- COMMAND ----------

INSERT OVERWRITE TABLE metering_reporting.meter_reg_id

SELECT * FROM meter_reg_id;

SELECT * FROM metering_reporting.meter_reg_id;
