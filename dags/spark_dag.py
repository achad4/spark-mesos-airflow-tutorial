import logging
import os
from datetime import date, timedelta
import airflow
from airflow import DAG, conf
from airflow.contrib.operators.spark_submit_operator import SparkSubmitOperator

LOG = logging.getLogger(__name__)

args = {'owner': 'airflow', 'retries': 0}

dag = DAG(
    dag_id='spark_hello_world',
    start_date=airflow.utils.dates.days_ago(2),
    schedule_interval='@daily',
    description=
    'Run the hello world Spark job',
    default_args=args)

executor_memory = '1G'
driver_memory = '1G'
job_cores = 1

spark_config = {
    'spark.mesos.executor.docker.image': 'tutorial',
    'spark.mesos.executor.home': '/opt/spark',
    'spark.mesos.uris': 'file:///etc/docker.tar.gz',
    'spark.cores.max': job_cores
}

task = SparkSubmitOperator(
    application='/python/spark_hello_world.py',
    task_id='spark_hello_world_task',
    conf=spark_config,
    conn_id='spark_mesos',
    total_executor_cores=job_cores,
    executor_memory=executor_memory,
    driver_memory=driver_memory,
    name='airflow',
    dag=dag)
