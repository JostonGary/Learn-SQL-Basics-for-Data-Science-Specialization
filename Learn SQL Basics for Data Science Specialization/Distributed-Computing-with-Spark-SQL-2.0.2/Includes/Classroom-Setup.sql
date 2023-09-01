-- Databricks notebook source
-- MAGIC
-- MAGIC %run "./Dataset-Mounts"

-- COMMAND ----------

CREATE DATABASE IF NOT EXISTS Databricks;
USE Databricks;

CREATE TABLE IF NOT EXISTS fireCalls
USING csv
OPTIONS (
  header "true",
  path "/mnt/davis/fire-calls/fire-calls-truncated-comma.csv",
  inferSchema "true"
);
