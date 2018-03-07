FROM internavenue/centos-base:centos7

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

# ---- #
# Java #
# ---- #

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
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
RUN cd ${INSTALL_DIR}
RUN curl -fSL "$SPARK_TGZ_URL" -o spark.tgz
RUN tar -xzf spark.tgz
RUN mv spark-* $SPARK_HOME && rm spark.tgz

WORKDIR ${SPARK_HOME}
