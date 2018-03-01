#!/bin/bash

TUTORIAL_HOME=$(pwd)

function buildImage() {
    docker build \
    --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -t tutorial .
}

function doco() { ( docker-compose -f "$TUTORIAL_HOME/docker-compose.yml" "$@" ); }

function docomesos() {
    doco run --rm --entrypoint bash mesos-slave -c "mesos-slave" ;
}

function createAirflowDb() {
    if [ ! $(psql -U postgres -h localhost -lqt | cut -d \| -f 1 | grep -qw airflow) ]; then
        docker exec -it postgresql bash -c 'psql -U postgres -c "create database airflow"'
    fi
}