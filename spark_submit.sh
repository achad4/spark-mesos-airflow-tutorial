dexec airflow_server /usr/local/spark/bin/spark-submit \
--master mesos://spark-mesos:7077 \
--conf spark.mesos.executor.docker.image=spark-mesos-dev \
--conf spark.mesos.executor.home=/opt/spark \
--name spark_job_3  \
--deploy-mode cluster \
/python/spark_hello_world.py