-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Delta Lake
-- MAGIC ## Module 4 Assignment
-- MAGIC
-- MAGIC This final assignment is broken up into 2 parts:
-- MAGIC 1. Completing this Delta Lake notebook
-- MAGIC   * Submitting question answers to Coursera
-- MAGIC   * Uploading notebook to Coursera for peer reviewing
-- MAGIC 2. Answering 3 free response questions on Coursera platform
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this notebook you:
-- MAGIC * Create a Delta table with partitioned columns
-- MAGIC * Delete records
-- MAGIC * Update existing records
-- MAGIC * Time travel!
-- MAGIC
-- MAGIC
-- MAGIC For each **bold** question, input its answer in Coursera.

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Create a new Delta table called `fireCallsPartitioned` partitioned by `Priority`.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsParquet
USING parquet
OPTIONS (
  path "/mnt/davis/fire-calls/fire-calls-clean.parquet/"
)

-- COMMAND ----------

-- TODO
CREATE DATABASE IF NOT EXISTS Databricks;
USE Databricks;
DROP TABLE IF EXISTS fireCallsPartitioned;
 
CREATE TABLE fireCallsPartitioned
USING DELTA
PARTITIONED BY (Priority)
AS
  SELECT * FROM fireCallsParquet;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 1
-- MAGIC
-- MAGIC **How many folders were created? Enter the number of records you see from the output below (include the `_delta_log` in your count).**

-- COMMAND ----------

-- MAGIC %fs ls dbfs:/user/hive/warehouse/databricks.db/firecallspartitioned

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 2
-- MAGIC
-- MAGIC **Delete all the records where `City` is null. How many records are left in the delta table?**

-- COMMAND ----------

-- TODO
DELETE FROM fireCallsPartitioned WHERE city IS NULL;

-- COMMAND ----------

SELECT COUNT(*) FROM fireCallsPartitioned WHERE Call_Type_Group = "Non Life-threatening"

-- COMMAND ----------

SELECT COUNT(*) FROM fireCallsPartitioned

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 3
-- MAGIC
-- MAGIC **After you deleted all records where the City is null, how many files were removed? Hint: Look at `operationsMetrics` in the transaction log using the `DESCRIBE HISTORY` command.**

-- COMMAND ----------

-- TODO
describe history firecallspartitioned

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 4
-- MAGIC
-- MAGIC **There are quite a few missing `Call_Type_Group` values. Use the `UPDATE` command to replace any null values with `Non Life-threatening`.**
-- MAGIC
-- MAGIC **After you replace the null values, how many `Non Life-threatening` call types are there?**

-- COMMAND ----------

-- TODO
UPDATE fireCallsPartitioned SET Call_Type_Group = "Non Life-threatening" WHERE (Call_Type_Group IS NULL)

-- COMMAND ----------

SELECT COUNT(*) FROM fireCallsPartitioned WHERE Call_Type_Group = "Non Life-threatening"

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 5
-- MAGIC
-- MAGIC **Travel back in time to the earliest version of the Delta table (version 0). How many records were there?**

-- COMMAND ----------

-- TODO
SELECT COUNT(*)
FROM fireCallsPartitioned
VERSION AS OF 0

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Congrats on finishing your last assignment notebook! 
-- MAGIC
-- MAGIC
-- MAGIC Now you will have to upload this notebook to Coursera for peer reviewing.
-- MAGIC 1. Make sure that all your code will run without errors
-- MAGIC   * Check this by clicking the "Clear State & Run All" dropdown option at the top of your notebook
-- MAGIC   * ![](http://files.training.databricks.com/images/eLearning/ucdavis/clearstaterunall.png)
-- MAGIC 2. Click on the "Workspace" icon on the side bar
-- MAGIC 3. Next to the notebook you're working in right now, click on the dropdown arrow
-- MAGIC 4. In the dropdown, click on "Export" then "HTML"
-- MAGIC   * ![](http://files.training.databricks.com/images/davis/upload_html_screenshot.png)
-- MAGIC 5. On the Coursera platform, upload this HTML file to Week 4's Peer Review Assignment
-- MAGIC
-- MAGIC Go back onto the Coursera platform for the free response portion of this assignment and for instructions on how to review your peer's work.
-- MAGIC

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>