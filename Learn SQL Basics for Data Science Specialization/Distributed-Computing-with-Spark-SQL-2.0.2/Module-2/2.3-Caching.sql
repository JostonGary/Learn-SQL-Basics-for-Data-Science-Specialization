-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 2.3 Caching
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this notebook you:<br>
-- MAGIC * Cache data for increased performance
-- MAGIC * Read the Spark UI

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## File Statistics
-- MAGIC
-- MAGIC Let's see how large our file is on disk.

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

-- MAGIC %fs ls /mnt/davis/fire-calls/fire-calls-truncated-comma.csv

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Count
-- MAGIC
-- MAGIC Let's see how long it takes to count all of the records in our dataset.

-- COMMAND ----------

SELECT count(*) FROM fireCalls

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Cache Table

-- COMMAND ----------

CACHE TABLE fireCalls

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ## Spark UI
-- MAGIC
-- MAGIC Wow! That took a long time to cache our data. Let's go ahead and take a look at it in the Spark UI.
-- MAGIC
-- MAGIC You'll notice that our data when cached actually takes up less space than our file on disk! That is thanks to the Tungsten Optimizer. You can learn more about Tungsten from Josh Rosen's [presentation](Deep Dive into Project Tungsten Bringing Spark Closer to Bare Metal ...) at Spark Summit.
-- MAGIC
-- MAGIC Our file in memory takes up ~59 MB, and on disk it takes up ~90 MB!
-- MAGIC <br><br>
-- MAGIC
-- MAGIC <div><img src="https://files.training.databricks.com/images/davis/cache_memory_2.3.png" style="height: 300px; border: 1px solid #aaa; border-radius: 10px 10px 10px 10px; box-shadow: 5px 5px 5px #aaa; margin: 20px"/></div>

-- COMMAND ----------

-- MAGIC %fs ls /mnt/davis/fire-calls/fire-calls-truncated-comma.csv

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Count (Again)
-- MAGIC
-- MAGIC Although it took a while to cache our data, every time we query our data, it should be lightning fast. See how long it takes to run the same query!

-- COMMAND ----------

SELECT count(*) FROM fireCalls

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Uncache Table
-- MAGIC
-- MAGIC Wow! That was a lot faster. Now, let's remove our table from the cache.

-- COMMAND ----------

UNCACHE TABLE fireCalls

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Lazy Cache
-- MAGIC
-- MAGIC Instead of waiting a minute to cache this dataset, we could do a "lazy cache". This means it will only cache the data as it is required.

-- COMMAND ----------

CACHE LAZY TABLE fireCalls

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Small Query
-- MAGIC
-- MAGIC This query was a lot faster to run. But, did it cache our entire dataset?

-- COMMAND ----------

SELECT * FROM fireCalls LIMIT 100

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Spark UI Part 2
-- MAGIC
-- MAGIC Why was only one partition cached? Turns out, to display 100 records, we don't need to cache our entire dataset. We only needed to materialize one partition. 

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Cache I
-- MAGIC
-- MAGIC Now let's do a `count()` on our dataset. Count forces you to go through every record of every partition of our dataset, so it ensures every data point will be cached.

-- COMMAND ----------

SELECT count(*) FROM fireCalls

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Count
-- MAGIC
-- MAGIC Look at how fast this call to `count()` is now!

-- COMMAND ----------

SELECT count(*) FROM fireCalls

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Clear Cache
-- MAGIC
-- MAGIC Let's remove any data that is currently cached.

-- COMMAND ----------

CLEAR CACHE

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>