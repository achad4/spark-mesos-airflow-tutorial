FROM python:3.6.4-alpine3.7

# ---- #
# Java #
# ---- #

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV JAVA_VERSION 8u151
ENV JAVA_ALPINE_VERSION 8.151.12-r0

#------ #
# Spark #
# ----- #

ARG INSTALL_DIR=/usr/local
ENV SPARK_HOME ${INSTALL_DIR}/spark
ENV SPARK_VERSION 2.2.1
ENV HADOOP_VERSION 2.7
ENV SPARK_TGZ_URL https://www.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz

COPY requirements/ /requirements/

RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home \
      && set -x \
	&& apk --update add --no-cache openjdk8="$JAVA_ALPINE_VERSION" bash \
      && apk add --no-cache --virtual .build-deps curl g++ \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ] \
      && cd ${INSTALL_DIR} \
      && set -x \
      && curl -fSL "$SPARK_TGZ_URL" -o spark.tgz \
      && tar -xzf spark.tgz \
      && mv spark-* spark \
      && rm spark.tgz \
      && cat /requirements/common.txt | grep pandas | xargs pip install --no-cache-dir \
      && rm -rf /requirements/ \
      && apk del .build-deps \
      && rm -rf /var/cache/apk/*

ARG AIRFLOW_VERSION=1.10.0
ARG AIRFLOW_HOME=/usr/local/airflow
ARG GROUP_USER=airflow

ENV AIRFLOW_HOME ${AIRFLOW_HOME}
ENV PYTHONPATH ${AIRFLOW_HOME}

COPY . ${AIRFLOW_HOME}/

RUN apk --update add postgresql-dev \
    && apk add --no-cache --virtual .build-deps \
          g++ \
          libxml2-dev \
          libxslt-dev \
          libffi-dev \
          linux-headers \
          git \
    && adduser -s /bin/ash -h ${AIRFLOW_HOME} -S airflow \
    && chown -R airflow: ${AIRFLOW_HOME} \
    && pip install --no-cache-dir -r ${AIRFLOW_HOME}/requirements/prod.txt \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

COPY spark_submit_hook.py /src/apache-airflow/airflow/contrib/hooks/spark_submit_hook.py

EXPOSE 8080 5555 8793

USER airflow

WORKDIR ${AIRFLOW_HOME}
