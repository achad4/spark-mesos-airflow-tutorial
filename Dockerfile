FROM python:3.6.4-stretch

RUN apt-get update
RUN apt-get install -y libcurl3 libevent-dev libsvn1 libsasl2-modules libcurl4-nss-dev default-jre-headless 

# ---- #
# Java #
# ---- #

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV JAVA_VERSION 8u151
ENV JAVA_ALPINE_VERSION 8.151.12-r0

# ---- #
# Mesos #
# ---- #

RUN wget http://repos.mesosphere.com/debian/pool/main/m/mesos/mesos_1.5.0-2.0.1.debian9_amd64.deb
RUN dpkg -i mesos_1.5.0-2.0.1.debian9_amd64.deb; exit 0 

#------ #
# Spark #
# ----- #

ARG INSTALL_DIR=/usr/local
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ENV SPARK_HOME ${INSTALL_DIR}/spark
ENV SPARK_VERSION 2.2.1
ENV HADOOP_VERSION 2.7
ENV SPARK_TGZ_URL https://www.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz

COPY requirements.txt /requirements.txt

RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home

RUN chmod +x /usr/local/bin/docker-java-home
RUN set -x
RUN echo "$(/usr/local/bin/docker-java-home)"
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/jre
# RUN [ "$JAVA_HOME" = "$(/usr/local/bin/docker-java-home)" ] 
RUN cd ${INSTALL_DIR}
RUN curl -fSL "$SPARK_TGZ_URL" -o spark.tgz
RUN tar -xzf spark.tgz
RUN mv spark-* $SPARK_HOME && rm spark.tgz

RUN pip install --no-cache-dir -r /requirements.txt

ARG AIRFLOW_VERSION=1.10.0
ARG AIRFLOW_HOME=/usr/local/airflow
ARG GROUP_USER=airflow

ENV AIRFLOW_HOME ${AIRFLOW_HOME}
ENV PYTHONPATH ${AIRFLOW_HOME}

COPY . ${AIRFLOW_HOME}/

RUN useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && chown -R airflow: ${AIRFLOW_HOME}

ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

EXPOSE 8080 5555 8793

USER airflow

WORKDIR ${AIRFLOW_HOME}
