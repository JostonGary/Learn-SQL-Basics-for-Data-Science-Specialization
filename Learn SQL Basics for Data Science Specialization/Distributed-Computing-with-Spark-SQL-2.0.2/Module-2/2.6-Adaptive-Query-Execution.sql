-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 2.6 Adaptive Query Execution
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this notebook you:<br>
-- MAGIC * Examine the Physical Plan that is generated for your queries
-- MAGIC * Enable Adaptive Query Execution (AQE) to reduce the runtime of your queries

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's make sure our data is accessible.

-- COMMAND ----------

USE databricks;

DESCRIBE fireCalls

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Examining Physical Plans

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's take a look at the shuffle partitions.

-- COMMAND ----------

SET spark.sql.adaptive.enabled = FALSE

-- COMMAND ----------

SELECT `call type`, count(*) AS count
FROM firecalls
GROUP BY `call type`
ORDER BY count DESC

-- COMMAND ----------

SET spark.sql.adaptive.enabled = TRUE

-- COMMAND ----------

SELECT `call type`, count(*) AS count
FROM firecalls
GROUP BY `call type`
ORDER BY count DESC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Now create the table `fireCallsParquet`.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsParquet
USING Parquet 
OPTIONS (
    path "/mnt/davis/fire-calls/fire-calls-8p.parquet"
  )

-- COMMAND ----------

-- MAGIC %md
-- MAGIC We can join these two datasets and examine the physical plan.
-- MAGIC
-- MAGIC Note that `fireCalls` is a much smaller dataset with 240,316 records vs `fireCallsParquet` which contains 4,799,622 records.

-- COMMAND ----------

SELECT * 
FROM fireCalls 
JOIN fireCallsParquet on fireCalls.`Call Number` = fireCallsParquet.`Call_Number`

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #### Automatic and Manual broadcasting
-- MAGIC
-- MAGIC - Depending on size of the data that is being loaded into Spark, Spark uses internal heuristics to decide how to join that data to other data.
-- MAGIC - Automatic broadcast depends on `spark.sql.autoBroadcastJoinThreshold`
-- MAGIC     - The setting configures the **maximum size in bytes** for a table that will be broadcast to all worker nodes when performing a join 
-- MAGIC     - Default is 10MB
-- MAGIC
-- MAGIC - A `broadcast` function can be used in Spark to instruct Catalyst that it should probably broadcast one of the tables that is being joined. 
-- MAGIC
-- MAGIC If the `broadcast` hint isn't used, but one side of the join is small enough (i.e., its size is below the threshold), that data source will be read into
-- MAGIC the Driver and broadcast to all Executors.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Now take a look at the physical plan when we broadcast one of the datasets.  The broadcast join hint is going to operate like a SQL hint, but Spark will still parse this even though it is commented out.

-- COMMAND ----------

SELECT /*+ BROADCAST(fireCalls) */ * 
FROM fireCalls 
JOIN fireCallsParquet on fireCalls.`Call Number` = fireCallsParquet.`Call_Number`

-- COMMAND ----------

-- MAGIC %md
-- MAGIC You might be wondering, why didn't Adaptive Query Execution automatically broadcast the dataset? Well, the entire dataset is ~59 MiB (size taken if you cache the data) which exceeds the default threshold of 10 MB.
-- MAGIC
-- MAGIC **The moral of the story**: if you identify a way to optimize your query (e.g. move the filter before the join, broadcast a table, etc), you should optimize it yourself instead of relying on Catalyst to optimize everything.
-- MAGIC

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>