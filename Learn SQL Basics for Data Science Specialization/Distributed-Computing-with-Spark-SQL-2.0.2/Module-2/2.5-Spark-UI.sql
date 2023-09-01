-- Databricks notebook source
-- MAGIC
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 2.5 Spark UI
-- MAGIC
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this notebook you:<br>
-- MAGIC * Analyze the Spark UI
-- MAGIC * Understand how distributed operations are implemented

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

SET spark.sql.adaptive.enabled = FALSE

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Count
-- MAGIC
-- MAGIC Let's start with a simple example of analyzing how `count()` is implemented.

-- COMMAND ----------

SELECT count(*) FROM fireCalls

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ## Stage Boundaries
-- MAGIC
-- MAGIC Start by expanding the Spark Job. You'll notice the job was broken into two stages. 
-- MAGIC
-- MAGIC <div><img src="http://files.training.databricks.com/images/davis/stage_boundary_2.5.png" style="height: 200px; border: 1px solid #aaa; border-radius: 10px 10px 10px 10px; box-shadow: 5px 5px 5px #aaa; margin: 20px"/></div>
-- MAGIC
-- MAGIC When we perform a count, each executor has to sum up their count locally. Only once all of them finish, then one slot is tasked with adding up all of the counts from the other executors. So it doesn't matter if you have one fast executor at counting - the bottleneck is the slowest executor :)

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ## Shuffle Write
-- MAGIC
-- MAGIC When our executors locally count their number of records, they have to write it to their local disk for that one designated executor to read. This causes a "shuffle write". Let's see that in the Spark UI. Click `View` to open up the Spark UI, then click `Description` for the second to last stage (should have 8 tasks).
-- MAGIC
-- MAGIC <div><br><img src="http://files.training.databricks.com/images/davis/2.5_shuffle_write.png" style="height: 300px; border: 1px solid #aaa; border-radius: 10px 10px 10px 10px; box-shadow: 5px 5px 5px #aaa; margin: 20px"/></div>
-- MAGIC
-- MAGIC You'll notice the **8 shuffle records** that were written out (each of them is very small).

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ## Shuffle Read
-- MAGIC
-- MAGIC When that designated executor reads in the "shuffle files" from the other executors that is called a "shuffle read". Click the `Description` for the last stage (should have one task).
-- MAGIC
-- MAGIC <div><br><img src="http://files.training.databricks.com/images/davis/shuffle_read_2.5.png" style="height: 400px; border: 1px solid #aaa; border-radius: 10px 10px 10px 10px; box-shadow: 5px 5px 5px #aaa; margin: 20px"/></div>
-- MAGIC
-- MAGIC You'll notice the **8 shuffle records** that were read in by one slot.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Examine the Spark UI

-- COMMAND ----------

SELECT `call type`, count(*) AS count
FROM fireCalls
GROUP BY `call type`
ORDER BY count DESC

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ## Skewed Partitions
-- MAGIC
-- MAGIC If you look at the Spark UI, you'll notice there is significant skew in our data. Most partitions don't actually have any records!
-- MAGIC
-- MAGIC <div><br><img src="https://files.training.databricks.com/images/davis/2.5_skew.png" style="height: 300px; border: 1px solid #aaa; border-radius: 10px 10px 10px 10px; box-shadow: 5px 5px 5px #aaa; margin: 20px"/></div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Do you recall that 200/200 parameter? Because of it, we have to have 200 resulting partitions, but the record count for each of those partitions is very small! Let's re-run this query but reduce the `spark.sql.shuffle.partitions` to 8.

-- COMMAND ----------

SET spark.sql.shuffle.partitions=8

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Re-run Query
-- MAGIC
-- MAGIC Let's try re-running that query.

-- COMMAND ----------

SELECT `call type`, count(*) AS count
FROM fireCalls
GROUP BY `call type`
ORDER BY count DESC

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC Great! You'll notice that the resulting partitions have a greater number of records and there is less skew across partitions.
-- MAGIC
-- MAGIC <div><br><img src="http://files.training.databricks.com/images/davis/2.5_shuffle_part.png" style="height: 300px; border: 1px solid #aaa; border-radius: 10px 10px 10px 10px; box-shadow: 5px 5px 5px #aaa; margin: 20px"/></div>
-- MAGIC

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2021 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>