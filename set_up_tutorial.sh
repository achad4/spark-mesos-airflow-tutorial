#!/bin/bash

TUTORIAL_HOME=$(pwd)
source $TUTORIAL_HOME/extras.sh

echo "Building Docker images..."
buildImages
echo "Initializing the Airflow postgres database"
docker volume create pg_data
docker volume create redis
doco up -d postgresql && sleep 5
createAirflowDb
