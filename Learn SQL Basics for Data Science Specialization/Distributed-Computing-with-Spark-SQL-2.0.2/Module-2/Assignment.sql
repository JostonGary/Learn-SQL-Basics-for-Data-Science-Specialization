-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Spark Internals
-- MAGIC ## Module 2 Assignment
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this assignment you:
-- MAGIC * Analyze the effects of caching data
-- MAGIC * Speed up Spark queries by changing default configurations
-- MAGIC
-- MAGIC For each **bold** question, input its answer in Coursera.

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Make sure nothing is already cached by clearing the cache (**NOTE**: This will affect all users on this cluster).

-- COMMAND ----------

CLEAR CACHE

-- COMMAND ----------

-- MAGIC %md
-- MAGIC
-- MAGIC ### Question 1
-- MAGIC
-- MAGIC **How many fire calls are in our `fireCalls` table?**

-- COMMAND ----------

-- TODO

-- COMMAND ----------

-- MAGIC %md
-- MAGIC
-- MAGIC ### Question 2
-- MAGIC
-- MAGIC **How large is our `fireCalls` dataset in memory?** Input just the numeric value (e.g. `51.2`) to Coursera.
-- MAGIC
-- MAGIC Cache the table, then navigate the Spark UI.

-- COMMAND ----------

-- TODO

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 3
-- MAGIC
-- MAGIC **Which "Unit Type" is the most common?**

-- COMMAND ----------

-- TODO

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 4
-- MAGIC
-- MAGIC **What type of transformation, `wide` or `narrow`, did the `GROUP BY` and `ORDER BY` queries result in? **

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 5
-- MAGIC
-- MAGIC **Looking at the query below, how many tasks are in the last stage of the last job?**
-- MAGIC
-- MAGIC Check the Spark UI and see how many tasks were launched. Did it use the shuffle partitions value defined? 

-- COMMAND ----------

SET spark.sql.shuffle.partitions=8;

SELECT `Neighborhooods - Analysis Boundaries`, AVG(Priority) as avgPriority
FROM fireCalls
GROUP BY `Neighborhooods - Analysis Boundaries`


-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>