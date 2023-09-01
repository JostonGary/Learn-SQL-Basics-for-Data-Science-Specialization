-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 3.4 File Formats
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this notebook you:<br>
-- MAGIC * Compare file formats and compression types
-- MAGIC * Examine Delta

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) Comparing File Formats<br>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's take a look at a colon delimited file sitting on S3.

-- COMMAND ----------

-- MAGIC %fs ls /mnt/davis/fire-calls/fire-calls-colon.txt

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Take a look at the first few lines of the file.

-- COMMAND ----------

-- MAGIC %fs head --maxBytes=1000 /mnt/davis/fire-calls/fire-calls-colon.txt

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Create a temporary view of the file using `:` as the separator.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsCSV
USING CSV 
OPTIONS (
    path "/mnt/davis/fire-calls/fire-calls-colon.txt",
    header "true",
    sep ":"
  )

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Take a look at the types of data in the table.

-- COMMAND ----------

DESCRIBE fireCallsCSV

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Are these data types correct? All of them are string types.
-- MAGIC
-- MAGIC We need to tell Spark to infer the schema.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsCSV
USING CSV 
OPTIONS (
    path "/mnt/davis/fire-calls/fire-calls-colon.txt",
    header "true",
    sep ":",
    inferSchema "true"
  )

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Now take a look at how Spark inferred the data types.

-- COMMAND ----------

DESCRIBE fireCallsCSV

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Wow, that took a long time just to figure out the schema for this file! 
-- MAGIC
-- MAGIC Now let's try the same thing with compressed files (Gzip and Bzip formats).
-- MAGIC
-- MAGIC Notice that the bzip file is the most compact - we will see if it is the fastest to operate on.

-- COMMAND ----------

-- MAGIC %fs ls /mnt/davis/fire-calls/fire-calls-colon.txt

-- COMMAND ----------

-- MAGIC %fs ls /mnt/davis/fire-calls/fire-calls-1p.txt.gz

-- COMMAND ----------

-- MAGIC %fs ls /mnt/davis/fire-calls/fire-calls-1p.txt.bzip

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's start by reading in the gzipped file.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsCSVgzip
USING CSV 
OPTIONS (
    path "/mnt/davis/fire-calls/fire-calls-1p.txt.gz",
    header "true",
    sep ":",
    inferSchema "true"
  )

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Wow! That took way longer than inferring the schema on the uncompressed data. Even though it took up less storage space, we had to pay for that in computation.
-- MAGIC
-- MAGIC You'll notice that the resulting view is comprised of only 1 partition, which makes this data very slow to query later on.

-- COMMAND ----------

-- MAGIC %python
-- MAGIC sql("SELECT * FROM fireCallsCSVgzip").rdd.getNumPartitions()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Let's compare the speed of reading in the gzip file to the bzip file!

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsCSVbzip
USING CSV 
OPTIONS (
    path "/mnt/davis/fire-calls/fire-calls-1p.txt.bzip",
    header "true",
    sep ":",
    inferSchema "true"
  )

-- COMMAND ----------

-- MAGIC %python
-- MAGIC sql("SELECT * FROM fireCallsCSVbzip").rdd.getNumPartitions()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC
-- MAGIC Bzip is a "splittable" file format, so it is much better to use than gzip when working with row-based formats for querying later on.
-- MAGIC
-- MAGIC Now let's go ahead and compare that to reading in from a columnar format: Parquet.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW fireCallsParquet
USING Parquet 
OPTIONS (
    path "/mnt/davis/fire-calls/fire-calls-1p.parquet"
  )

-- COMMAND ----------

DESCRIBE fireCallsParquet

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Look at how fast it is to get the schema from a Parquet file! That is because the Parquet file stores the data and the associated metadata.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Compare the performance between the three file types. We are going to use a Python helper function called [timeit](https://ipython.org/ipython-doc/3/interactive/magics.html#magic-timeit) to calculate how long the query takes to execute.

-- COMMAND ----------

-- MAGIC %python
-- MAGIC parquetDF = sql("SELECT * FROM fireCallsParquet")
-- MAGIC %timeit -n1 -r1 parquetDF.select("City").where("City == 'San Francisco'").count()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC csvDF = sql("SELECT * FROM fireCallsCSV")
-- MAGIC %timeit -n1 -r1 csvDF.select("City").where("City == 'San Francisco'").count()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC gzipDF = sql("SELECT * FROM fireCallsCSVgzip")
-- MAGIC %timeit -n1 -r1 gzipDF.select("City").where("City == 'San Francisco'").count()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC bzipDF = sql("SELECT * FROM fireCallsCSVbzip")
-- MAGIC %timeit -n1 -r1 bzipDF.select("City").where("City == 'San Francisco'").count()

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ##![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) Reading from Delta Files
-- MAGIC
-- MAGIC "Apache Parquet is a columnar storage format available to any project in the Hadoop ecosystem, regardless of the choice of data processing framework, data model or programming language."
-- MAGIC
-- MAGIC <div style="text-align:right">
-- MAGIC ![parquet logo](https://parquet.apache.org/assets/img/parquet_logo.png)<br>
-- MAGIC <a href="https://parquet.apache.org/" target="_blank">https&#58;//parquet.apache.org</a></div>

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC Delta is built on Parquet, is also open source, and provides certain benefits beyond Parquet (more on this in later notebooks).
-- MAGIC
-- MAGIC <div style="text-align:right">
-- MAGIC ![delta logo](https://live-delta-io.pantheonsite.io/wp-content/uploads/2019/04/delta-lake-logo-tm.png)<br>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### About Delta Files
-- MAGIC * Free & Open Source.
-- MAGIC * Increased query performance over row-based data stores.
-- MAGIC * Provides efficient data compression.
-- MAGIC * Designed for performance on large data sets.
-- MAGIC * Supports schema evolution.
-- MAGIC * Is a splittable "file format".
-- MAGIC * A <a href="https://en.wikipedia.org/wiki/Column-oriented_DBMS" target="_blank">Column-Oriented</a> data store
-- MAGIC
-- MAGIC **Row Format**
-- MAGIC
-- MAGIC | ID | Name | Score |
-- MAGIC |----|------|-------|
-- MAGIC | 1 | john | 4.1 |
-- MAGIC | 2 | mike | 3.5 |
-- MAGIC | 3 | sally | 6.4 |
-- MAGIC
-- MAGIC **Column Format**
-- MAGIC
-- MAGIC | ID | 1 | 2 | 3 |
-- MAGIC |----|------|-------|-------|
-- MAGIC | Name | john | mike | sally |
-- MAGIC | Score | 4.1 | 3.5 | 6.4 |
-- MAGIC
-- MAGIC See also
-- MAGIC
-- MAGIC
-- MAGIC * <a href="https://delta.io/" target="_blank">https&#58;//delta.io/</a>
-- MAGIC * <a href="https://parquet.apache.org/" target="_blank">https&#58;//parquet.apache.org</a>
-- MAGIC * <a href="https://en.wikipedia.org/wiki/Apache_Parquet" target="_blank">https&#58;//en.wikipedia.org/wiki/Apache_Parquet</a>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Write out to a delta table.

-- COMMAND ----------

DROP TABLE IF EXISTS fireCallsDelta;

CREATE TABLE fireCallsDelta
USING delta
AS
  SELECT /*+ REPARTITION(8) */ *
  FROM fireCallsParquet

-- COMMAND ----------

DESCRIBE EXTENDED fireCallsDelta

-- COMMAND ----------

-- MAGIC %python
-- MAGIC dbutils.fs.ls("/user/hive/warehouse/databricks.db/firecallsdelta")

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Now compare reading from a CSV file to reading from Delta.

-- COMMAND ----------

SELECT count(`Incident Number`)
FROM firecallsCSV
WHERE Priority > 1

-- COMMAND ----------

SELECT count(`Incident_Number`)
FROM fireCallsDelta
WHERE Priority > 1

-- COMMAND ----------

-- MAGIC %md
-- MAGIC The Delta file has 8 partitions rather than 1. Look at the speed improvement!

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##Reading CSV
-- MAGIC - `spark.read.csv(..)`
-- MAGIC - There are a large number of options when reading CSV files including headers, column separator, escaping, etc.
-- MAGIC - We can allow Spark to infer the schema at the cost of first reading in the entire file
-- MAGIC - Large CSV files should always have a schema pre-defined

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Reading Parquet
-- MAGIC - `spark.read.parquet(..)`
-- MAGIC - Parquet files are the preferred file format for big-data
-- MAGIC - It is a columnar file format
-- MAGIC - It is a splittable file format
-- MAGIC - It offers a lot of performance benefits over other formats including predicate push down
-- MAGIC - Unlike CSV, the schema is read in, not inferred
-- MAGIC - Reading the schema from Parquet's metadata can be extremely efficient

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC ## Comparison
-- MAGIC | Type    | <span style="white-space:nowrap">Inference Type</span> | <span style="white-space:nowrap">Inference Speed</span> | Reason                                          | <span style="white-space:nowrap">Should Supply Schema?</span> |
-- MAGIC |---------|--------------------------------------------------------|---------------------------------------------------------|----------------------------------------------------|:--------------:|
-- MAGIC | <b>CSV</b>     | <span style="white-space:nowrap">Full-Data-Read</span> | <span style="white-space:nowrap">Slow</span>            | <span style="white-space:nowrap">File size</span>  | Yes            |
-- MAGIC | <b>Parquet</b> | <span style="white-space:nowrap">Metadata-Read</span>  | <span style="white-space:nowrap">Fast/Medium</span>     | <span style="white-space:nowrap">Number of Partitions</span> | No (most cases)             |
-- MAGIC | <b>Tables</b>  | <span style="white-space:nowrap">n/a</span>            | <span style="white-space:nowrap">n/a</span>            | <span style="white-space:nowrap">Predefined</span> | n/a            |
-- MAGIC | <b>JSON</b>    | <span style="white-space:nowrap">Full-Read-Data</span> | <span style="white-space:nowrap">Slow</span>            | <span style="white-space:nowrap">File size</span>  | Yes            |
-- MAGIC | <b>Text</b>    | <span style="white-space:nowrap">Dictated</span>       | <span style="white-space:nowrap">Zero</span>            | <span style="white-space:nowrap">Only 1 Column</span>   | Never          |
-- MAGIC | <b>JDBC</b>    | <span style="white-space:nowrap">DB-Read</span>        | <span style="white-space:nowrap">Fast</span>            | <span style="white-space:nowrap">DB Schema</span>  | No             |

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Reading Tables
-- MAGIC - `spark.read.table(..)`
-- MAGIC - The Databricks platform allows us to register a huge variety of data sources as tables via the Databricks UI
-- MAGIC - Any `DataFrame` (from CSV, Parquet, whatever) can be registered as a temporary view
-- MAGIC - Tables/Views can be loaded via the `DataFrameReader` to produce a `DataFrame`
-- MAGIC - Tables/Views can be used directly in SQL statements

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Reading JSON
-- MAGIC - `spark.read.json(..)`
-- MAGIC - JSON represents complex data types unlike CSV's flat format
-- MAGIC - Has many of the same limitations as CSV (needing to read the entire file to infer the schema)
-- MAGIC - Like CSV has a lot of options allowing control on date formats, escaping, single vs. multiline JSON, etc.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Reading Text
-- MAGIC - `spark.read.text(..)`
-- MAGIC - Reads one line of text as a single column named `value`
-- MAGIC - Is the basis for more complex file formats such as fixed-width text files

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Reading JDBC
-- MAGIC - `spark.read.jdbc(..)`
-- MAGIC - Requires one database connection per partition
-- MAGIC - Has the potential to overwhelm the database
-- MAGIC - Requires specification of a stride to properly balance partitions
-- MAGIC

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>