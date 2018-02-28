import os
from pyspark.sql import DataFrame as sparkDF
from pyspark.sql.functions import col, size, array_contains
from pyspark.sql import functions as func
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, TimestampType, ArrayType
from pyspark.sql import SparkSession
from pyspark import SparkContext
from pyspark.conf import SparkConf
from pyspark.sql.types import *

conf = SparkConf()
sc = SparkContext(conf=conf)
spark = SparkSession.builder.getOrCreate()
print("AIRFLOW")
cSchema = StructType([StructField("WordList", ArrayType(StringType()))])
test_list = [['Hello', 'world']], [['I', 'am', 'fine']]
df = spark.createDataFrame(test_list,schema=cSchema) 
print("Hello World")
print(df.show())
spark.stop()
