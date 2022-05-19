# Databricks notebook source
# MAGIC %md
# MAGIC 
# MAGIC # Metering Model Executor
# MAGIC 
# MAGIC 
# MAGIC ### Run Order
# MAGIC 
# MAGIC   1. live_mpxn_afms_view
# MAGIC   2. Dual_Fuel_Report
# MAGIC   3. live_mpxn_afms_billing_view
# MAGIC   4. meter_reg_id
# MAGIC   
# MAGIC   
# MAGIC #### live_mpxn_afms_view
# MAGIC 
# MAGIC The live MPAN_AFMS view does the following:
# MAGIC -  Builds a live Elec MPAN table
# MAGIC -  Builds a live Elec MPAN table
# MAGIC -  Creates an output table
# MAGIC -  Creates exception tables
# MAGIC 
# MAGIC 
# MAGIC #### Dual_Fuel_Report
# MAGIC 
# MAGIC -  creates a Junifer dual fuel report:
# MAGIC -  Populates a table which identifies the fuel type at a given supply address. Each MPXN is placed into one of 3 categories;
# MAGIC 
# MAGIC 
# MAGIC   1. Dual Fuel
# MAGIC   2. Elec Single
# MAGIC   3. Gas Single 
# MAGIC 
# MAGIC 
# MAGIC -  Creates a SAP dual fuel report
# MAGIC -  Creates exception report 'not in billing engine'
# MAGIC 
# MAGIC #### live_mpxn_afms_billing_view
# MAGIC 
# MAGIC -  Uses the live_mpan & live_MPRN tables to create a single table
# MAGIC -  uses the Junifer and SAP dual Fuel reports to provide tariff info
# MAGIC 
# MAGIC #### meter_reg_id
# MAGIC 
# MAGIC -  Creates a meter register level report which gives information about each meter register on an electric meter

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #### Run live_mpxn_afms_view notebook

# COMMAND ----------

dbutils.notebook.run(
  "/Users/Dalton.Hoskins@ecotricity.co.uk/Metering Model/live_mpxn_afms_view",
  3600
)

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #### Run Dual_Fuel_Report Notebook

# COMMAND ----------

dbutils.notebook.run(
  "Dual_Fuel_Report",
  3600
)

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #### Run live_mpxn_afms_billing_view Notebook

# COMMAND ----------

dbutils.notebook.run(
  "/Users/Dalton.Hoskins@ecotricity.co.uk/Metering Model/live_mpxn_afms_billing_view",
  3600
)

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #### Run meter_reg_id Notebook

# COMMAND ----------

dbutils.notebook.run(
  "meter_reg_id",
  3600
)
