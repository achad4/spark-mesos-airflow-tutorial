docker exec -it server bash -c '/usr/local/spark/bin/spark-submit \
--master mesos://spark-mesos:7077 \
--conf spark.mesos.executor.docker.image=tutorial \
--conf spark.mesos.executor.home=/usr/local/spark/ \
--name spark_job_3  \
--deploy-mode cluster \
/python/spark_hello_world.py'