#!/usr/bin/env bash

# wait_for_redis() {
#     if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]
#         then
#         wait_for_port "Redis" "$REDIS_HOST" "6379"
#     fi
# }

if [ "$1" == "webserver" ]; then
    airflow initdb
    sleep 5
    # python /usr/local/airflow/insert_conn.py
    airflow webserver
elif [ "$1" == "scheduler" ]; then
    # sleep 10
    airflow scheduler
elif [ "$1" == "worker" ]; then
    # sleep 10
    airflow worker
else
    echo "available options: webserver, scheduler or worker"
fi