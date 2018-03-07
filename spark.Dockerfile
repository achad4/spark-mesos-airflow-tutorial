FROM internavenue/centos-base:centos7

#RUN yum update
RUN set -x && yum install -y \
  python36 \
  wget \
  bzip2 \
  git \
  java-1.8.0-openjdk \
  java-1.8.0-openjdk-devel \
  tar \
  unzip \
  && \
  yum clean all
# libcurl3 libevent-dev libsvn1 libsasl2-modules libcurl4-nss-dev 
#default-jre-headless 

# ---- #
# Java #
# ---- #

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
# ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV PATH $PATH:/usr/lib/jvm/java-1.8.0-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV JAVA_VERSION 8u151
ENV JAVA_ALPINE_VERSION 8.151.12-r0

# ---- #
# Mesos #
# ---- #

RUN rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm  \
	&& yum -y install mesos mesosphere-zookeeper

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

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk/
# RUN [ "$JAVA_HOME" = "$(/usr/local/bin/docker-java-home)" ] 
RUN cd ${INSTALL_DIR}
RUN curl -fSL "$SPARK_TGZ_URL" -o spark.tgz
RUN tar -xzf spark.tgz
RUN mv spark-* $SPARK_HOME && rm spark.tgz

# COPY requirements.txt /requirements.txt

# RUN { \
# 		echo '#!/bin/sh'; \
# 		echo 'set -e'; \
# 		echo; \
# 		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
# 	} > /usr/local/bin/docker-java-home

# RUN chmod +x /usr/local/bin/docker-java-home

# RUN echo "$(/usr/local/bin/docker-java-home)"


# RUN pip3 install --no-cache-dir -r /requirements.txt

#ENV SPARK_LOCAL_IP APT127.0.0.1

WORKDIR ${SPARK_HOME}
