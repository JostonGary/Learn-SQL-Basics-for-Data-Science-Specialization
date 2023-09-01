-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 4.5 Advanced Delta Lake
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this notebook you:<br>
-- MAGIC * [PARTITION](https://docs.databricks.com/delta/best-practices.html#language-sql) columns of your table 
-- MAGIC * Evolve the schema of the table
-- MAGIC * [Time travel](https://databricks.com/blog/2019/02/04/introducing-delta-time-travel-for-large-scale-data-lakes.html)!
-- MAGIC * [DELETE](https://docs.databricks.com/spark/latest/spark-sql/language-manual/delta-delete-from.html) records

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
-- MAGIC ### Partitioning
-- MAGIC
-- MAGIC Create Delta Table [partitioned by](https://docs.databricks.com/delta/best-practices.html#language-sql) City.
-- MAGIC
-- MAGIC You are not required to partition the columns in your Delta table, but doing so can drastically speed up queries. From the Delta [docs](https://docs.delta.io/latest/best-practices.html#choose-the-right-partition-column), there are two rules of thumb for deciding which column to partition by:
-- MAGIC   * If the cardinality of a column will be very high, do not use that column for partitioning. For example, if you partition by a column userId and if there can be 1M distinct user IDs, then that is a bad partitioning strategy.
-- MAGIC   * Amount of data in each partition: You can partition by a column if you expect data in that partition to be at least 1 GB.

-- COMMAND ----------

CREATE DATABASE IF NOT EXISTS Databricks;
USE Databricks;
DROP TABLE IF EXISTS fireCallsDelta;

CREATE TABLE fireCallsDelta
USING DELTA
PARTITIONED BY (City)
AS 
  SELECT * FROM fireCallsParquet

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's take a look how these underlying files are partitioned on disk.

-- COMMAND ----------

-- MAGIC %fs ls dbfs:/user/hive/warehouse/databricks.db/firecallsdelta

-- COMMAND ----------

SELECT * FROM fireCallsDelta WHERE City="Daly City"

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Schema Enforcement & Evolution
-- MAGIC **Schema enforcement**, also known as schema validation, is a safeguard to ensure data quality.  Delta Lake uses schema validation *on write*, which means that all new writes to a table are checked for compatibility with the target table’s schema at write time. If the schema is not compatible, Delta Lake cancels the transaction altogether (no data is written), and raises an exception to let the user know about the mismatch.
-- MAGIC
-- MAGIC **Schema evolution** is a feature that allows users to easily change a table’s current schema to accommodate data that is changing over time. Most commonly, it’s used when performing an append or overwrite operation, to automatically adapt the schema to include one or more new columns.
-- MAGIC
-- MAGIC To determine whether a write to a table is compatible, Delta Lake uses the following rules. The DataFrame to be written:
-- MAGIC * Cannot contain any additional columns that are not present in the target table’s schema. 
-- MAGIC * Cannot have column data types that differ from the column data types in the target table.
-- MAGIC * Cannot contain column names that differ only by case.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC If we look at the schema, we can that someone added a few too many `o's` to the column `Neighborhooods_-_Analysis_Boundaries`. Let's create a new column called `Neighborhoods`.

-- COMMAND ----------

DESCRIBE fireCallsDelta

-- COMMAND ----------

INSERT OVERWRITE TABLE fireCallsDelta SELECT *, `Neighborhooods_-_Analysis_Boundaries` AS Neighborhoods FROM fireCallsDelta

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Our write failed because we changed the schema. Let's enable `autoMerge`.

-- COMMAND ----------

SET spark.databricks.delta.schema.autoMerge.enabled=TRUE

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's try this command again.

-- COMMAND ----------

INSERT OVERWRITE TABLE fireCallsDelta SELECT *, `Neighborhooods_-_Analysis_Boundaries` AS Neighborhoods FROM fireCallsDelta;

SELECT * FROM fireCallsDelta

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Time Travel
-- MAGIC Now, let's try querying with the `VERSION AS OF` command. We can see the data we previously deleted. There is also `TIMESTAMP AS OF`:
-- MAGIC ```
-- MAGIC SELECT * FROM table_identifier TIMESTAMP AS OF timestamp_expression
-- MAGIC SELECT * FROM table_identifier VERSION AS OF version
-- MAGIC ``` 

-- COMMAND ----------

SELECT * 
FROM fireCallsDelta 
  VERSION AS OF 0

-- COMMAND ----------

SELECT * 
FROM fireCallsDelta 
  VERSION AS OF 1

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Delete
-- MAGIC
-- MAGIC With laws such as [GDPR](https://en.wikipedia.org/wiki/General_Data_Protection_Regulation) and [CCPA](https://en.wikipedia.org/wiki/California_Consumer_Privacy_Act), individuals have the right to forgotten and their data erased. 
-- MAGIC
-- MAGIC For sake of example, let's delete the record corresponding to Incident Number `14055109`. Luckily, this is very easy with Delta Lake and we do not need to ingest our entire data and rewrite it just to remove one record.

-- COMMAND ----------

SELECT * FROM fireCallsDelta WHERE Incident_Number = "14055109"

-- COMMAND ----------

DELETE FROM fireCallsDelta WHERE Incident_Number = "14055109";

SELECT * FROM fireCallsDelta WHERE Incident_Number = "14055109"


-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>