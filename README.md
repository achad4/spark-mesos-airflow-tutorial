# Mesos + Spark + Airflow in Docker Compose
Mesos and Spark are powerful technologies for processing large workloads on a distributed cluster. Airflow is a framework to write, schedule, and monitor jobs. In conjunction, these three technologies provide a user friendly and powerful way to manage process large data sets. This tutorial will walk through how to schedule Spark jobs with Airflow, distributing the Spark tasks across a Mesos cluster. We'll set this all up locally using `docker-compose`.

## Requirements
- Docker installed with at least 4 GB of memory allocated to the docker machine

## Setup
- Add the zookeeper alias /etc/hosts. This is necessary because mesos will execute `docker run` within the docker-compose `sandbox` network and therefore cannot resolve the container's host name.
```
127.0.0.1 zookeeper zk
```
- Source the bash tools
```
source extras.sh
```
- Build the image (this will take a few mins as it installs some heavy duty packages, but you only need to do it once!) and initialize the persistent stores
```
./set_up_tutorial.sh
```

## Spark Mesos Cluster in compose
- The cluster consists of a single mesos master and slave communicating via zookeeper
- The mesos slave uses the mesos Docker containerizer (`MESOS_CONTAINERIZERS: docker`) to execute jobs
- The mesos slave container will actually execute docker using your local docker machine. Notice these lines in the `docker-compose` file
```
- ~/docker.tar.gz:/etc/docker.tar.gz
- /usr/local/bin/docker:/usr/bin/docker
- /var/run/docker.sock:/var/run/docker.sock
```
- `docker.tar.gz` contains your credentials and allows mesos to pull from a private registry. The second two lines just mount the docker executable 
## Start Mesos
- doco up mesos-master spark-mesos && docomesos
	- The `docomesos` alias is a workaround: don't ask me why but the `mesos-slave` process only stays alive when run in the foreground in docker-compose for mac. `docker run -it --entrypoint=bash mesos -c "mesos-slave"` accomplishes this.
- Submit a pyspark job to the cluster
	- **WARNING**: a common error here is a nullpointer in spark webserver at  `org.apache.spark.scheduler.cluster.mesos.MesosClusterScheduler.revive` which manifests itself as a Json parse exception on the client side. This is a result of the Spark mesos scheduler not cleanly unregistering from the mesos master and can be solved by bringing down mesos and removing the working directory: `docker rm -f spark-mesos mesos-master mesos-slave && rm -rf /tmp/mesos`
- Notice in the `docker-compose` file the line `/tmp/mesos:/tmp/mesos`. When the mesos slave launches a task it will create and pull files into a "sandbox" directory, which will in turn be mounted into the container that it executes. We therefore need to mount the hosts `/tmp/mesos` directory into the mesos slave container so that when it executes `docker run ...` it will be able to mount the sandbox directory into the container (i.e. so that `docker.sailthru.com/nimbus/spark:beta-2.1.1-2.2.0-2-hadoop-2.7_3` will have access to `python/spark_test.py`)
	- This has the added benefit of making the mesos logs easy to find. Just search your `/tmp/mesos` directory.
- The `spark-mesos` container runs the `MesosClusterDispatcher` class, connecting to the mesos cluster via zookeeper. 
	- It will start the `CoarseGrainedSchedulerBackend` with which Spark executors will register, more on that later.
- After you start up the `spark-mesos` container, you should be able to see a framework registered under the name "spark" in your mesos cluser (`localhost:5050`). This is the framework that will launch your spark tasks.
- Before submitting the spark task, we need to slightly modify the spark image to work with out local cluster, namely remove the mesos node contraints and add our AWS credentials from our local environment.
```
cd ~/dev/devtools/containers/mesos && ./build_dev_image.sh
```
- Submit a Spark task:
```
dexec server /usr/local/spark/bin/spark-submit --master mesos://spark-mesos:7077 --conf spark.mesos.executor.docker.image=spark-mesos-dev --conf spark.mesos.executor.home=/opt/spark --name spark_job_1 --deploy-mode cluster /usr/local/ds-jobs/lib/etl/spark_hello_world.py
Using Spark's default log4j profile: org/apache/spark/log4j-defaults.properties
18/02/26 17:45:59 INFO RestSubmissionClient: Submitting a request to launch an application in mesos://spark-mesos:7077.
18/02/26 17:46:01 INFO RestSubmissionClient: Submission successfully created as driver-20180226174600-0001. Polling submission state...
18/02/26 17:46:01 INFO RestSubmissionClient: Submitting a request for the status of submission driver-20180226174600-0001 in mesos://spark-mesos:7077.
18/02/26 17:46:01 INFO RestSubmissionClient: State of driver driver-20180226174600-0001 is now RUNNING.
18/02/26 17:46:01 INFO RestSubmissionClient: Server responded with CreateSubmissionResponse:
{
  "action" : "CreateSubmissionResponse",
  "serverSparkVersion" : "2.2.1",
  "submissionId" : "driver-20180226174600-0001",
  "success" : true
}
```
- Go to `localhost:5050`, click the `Spark` framework under `Active Frameworks`. After a few seconds, you'll see one completed task called "Driver for spark_job_1". Go to the `sandbox` which will contain the `stderr` and `stdout` files.
- In the stderr logs you'll see something like what's below. This shows the `CoarseGrainedExecutorBackend` connecting the the scheduler, ready to execute tasks. The Spark driver has its own DAG scheduler that will send the executor tasks and listen for status updates.
```
I0221 16:45:30.106727   107 exec.cpp:161] Version: 1.0.1
I0221 16:45:30.112429   113 exec.cpp:236] Executor registered on agent 2d4d0022-88b2-4778-b32a-c8e4967fbf07-S0
I0221 16:45:30.114163   113 docker.cpp:809] Running docker -H unix:///var/run/docker.sock run 
<docker options....>
-c  "/opt/spark/./bin/spark-class" org.apache.spark.executor.CoarseGrainedExecutorBackend 
--driver-url spark://CoarseGrainedScheduler@192.168.65.3:39757 --executor-id 0 --hostname localhost
--cores 1 --app-id 2d4d0022-88b2-4778-b32a-c8e4967fbf07-0000-driver-20180221164521-0001
```
- In the `stdout` file, you'll find the output of your pyspark script:
```
<Some Mesos / Spark stuff.... >
Registered docker executor on localhost
Starting task driver-20180221181056-0001
Hello World
+--------------+
|      WordList|
+--------------+
|[Hello, world]|
| [I, am, fine]|
+--------------+
```

## Start Airflow
Now that we've been able to successfully submit a Spark python job to our Mesos cluster, let's use the `SparkSubmitOperator` to run the same pyspark job with Airflow. 
- `doco up server scheduler worker`
- Create the spark mesos connection in the UI `http://localhost:8080/admin/connection/`
```
conn_id: spark_mesos
Host: spark-mesos
Extra: {"deploy-mode": “cluster”, "spark-home": "/usr/local/spark"}
```
- Import and use the SparkSubmitOperator in your DAG 
```

hello_world = SparkSubmitOperator(
    application='python/spark_test.py',
    task_id='spark_example',
    conf={
        'spark.mesos.executor.docker.image': 'spark-mesos-dev',
        'spark.mesos.executor.home': '/opt/spark'
    },
    conn_id='spark_mesos',
    total_executor_cores=1,
    executor_memory='1G',
    name='airflow',
    dag=dag
)
```
- You can view the logs for your Airflow scheduled Spark job the same way as before, but notice the name of the task under the `Spark` framework will be "airflow" and not "spark_job_1"




