-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 4.4 Delta Lake
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this notebook you:<br>
-- MAGIC * Create medallion architecture (bronze, silver, gold) with [Delta Lake](http://delta.io/)
-- MAGIC * Analyze Delta [transaction log](https://databricks.com/blog/2019/08/21/diving-into-delta-lake-unpacking-the-transaction-log.html)
-- MAGIC * [UPDATE](https://databricks.com/blog/2020/09/29/diving-into-delta-lake-dml-internals-update-delete-merge.html) existing data
-- MAGIC
-- MAGIC ![](https://files.training.databricks.com/images/davis/delta_multihop.png)

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Create a temporary view with our Parquet file.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsParquet
USING parquet
OPTIONS (
  path "/mnt/davis/fire-calls/fire-calls-clean.parquet/"
)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC
-- MAGIC <h2> Write raw data into Delta Bronze</h2>
-- MAGIC
-- MAGIC <img width="75px" src="https://files.training.databricks.com/images/davis/images_bronze.png">
-- MAGIC
-- MAGIC All we need to do to create a Delta table is to specify `USING DELTA`.

-- COMMAND ----------

CREATE DATABASE IF NOT EXISTS Databricks;
USE Databricks;
DROP TABLE IF EXISTS fireCallsBronze;

CREATE TABLE fireCallsBronze
USING DELTA
AS 
  SELECT * FROM fireCallsParquet

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Navigate to the `Data` tab and take a look at the `fireCallsBronze` table in the `Databricks` database.
-- MAGIC
-- MAGIC <img width="550px" src="https://s3-us-west-2.amazonaws.com/files.training.databricks.com/images/davis/firecallsbronze.png">

-- COMMAND ----------

-- MAGIC %md
-- MAGIC You will notice that there is a `Details` tab showing you when the table was created, last modified, how many partitions, size of data, etc.
-- MAGIC
-- MAGIC <img width="290px" src="https://s3-us-west-2.amazonaws.com/files.training.databricks.com/images/davis/firecallsbronzedetails.png">

-- COMMAND ----------

-- MAGIC %md
-- MAGIC There is also a history tab that shows all of the versions of the delta table. 
-- MAGIC
-- MAGIC
-- MAGIC ![](https://s3-us-west-2.amazonaws.com/files.training.databricks.com/images/davis/firecallsbronzehistory.png)
-- MAGIC
-- MAGIC We can take a look at the underlying files that were generated. You'll notice that there are 8 parquet files corresponding to the 8 partitions of data, as well as a `_delta_log` directory.

-- COMMAND ----------

-- MAGIC %fs ls dbfs:/user/hive/warehouse/databricks.db/firecallsbronze

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's dig into the delta log directory and take a look at the first JSON record.

-- COMMAND ----------

-- MAGIC %fs head dbfs:/user/hive/warehouse/databricks.db/firecallsbronze/_delta_log/00000000000000000000.json

-- COMMAND ----------

-- MAGIC %md
-- MAGIC
-- MAGIC ## Refine bronze tables, write to Delta Silver
-- MAGIC
-- MAGIC <img width="75px" src="https://files.training.databricks.com/images/davis/images_silver.png">
-- MAGIC
-- MAGIC Filter unnecessary columns and nulls.

-- COMMAND ----------

DROP TABLE IF EXISTS fireCallsSilver;

CREATE TABLE fireCallsSilver 
USING DELTA
AS 
  SELECT Call_Number, Call_Type, Call_Date, Received_DtTm, Address, City, Zipcode_of_Incident, Unit_Type, `Neighborhooods_-_Analysis_Boundaries`
  FROM fireCallsBronze
  WHERE (City IS NOT null) AND (`Neighborhooods_-_Analysis_Boundaries` <> "None");
  
SELECT * FROM fireCallsSilver LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC You can see that there is certainly more cleaning that could have happened (e.g. converting all occurrences of `SF` to `San Francisco` for `City`).
-- MAGIC
-- MAGIC Let's fix it and make an updated version of this Silver table using [UPDATE](https://docs.databricks.com/delta/delta-update.html).

-- COMMAND ----------

UPDATE fireCallsSilver SET City = "San Francisco" WHERE (City = "SF") OR (City = "SAN FRANCISCO")

-- COMMAND ----------

-- MAGIC %md
-- MAGIC We can see how this is reflected in the transaction log.

-- COMMAND ----------

DESCRIBE HISTORY fireCallsSilver

-- COMMAND ----------

-- MAGIC %fs head dbfs:/user/hive/warehouse/databricks.db/firecallssilver/_delta_log/00000000000000000001.json

-- COMMAND ----------

-- MAGIC %md
-- MAGIC
-- MAGIC ## Aggregate data, write to Delta Gold
-- MAGIC
-- MAGIC <img width="75px" src="https://files.training.databricks.com/images/davis/images_gold.png">
-- MAGIC
-- MAGIC Aggregate call type by neighborhood. This will automatically use the latest version of the `fireCallsSilver` table.

-- COMMAND ----------

DROP TABLE IF EXISTS fireCallsGold;

CREATE TABLE fireCallsGold 
USING DELTA
AS 
  SELECT `Neighborhooods_-_Analysis_Boundaries` as Neighborhoods, Call_Type, count(*) as Count
  FROM fireCallsSilver
  GROUP BY Neighborhoods, Call_Type

-- COMMAND ----------

SELECT * FROM fireCallsGold LIMIT 10


-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>