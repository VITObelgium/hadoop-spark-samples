#!/bin/bash

#Source the environment variables to point to the new cluster
set -a
source ../scripts/source_new_cluster

#The used docker image
IMAGE="vito-docker.artifactory.vgt.vito.be/spark-docker-sample-advanced:latest"
#These mounts are required for authentication purposes and for communication between the container and the cluster.
MOUNTS="/var/lib/sss/pipes:/var/lib/sss/pipes:rw,/usr/local/hadoop/:/usr/local/hadoop/:ro,/etc/krb5.conf:/etc/krb5.conf:ro,/data:/data:ro"
#The Python that is installed in the docker container
PYSPARK_PYTHON="/opt/env/bin/python3.11"

${SPARK_HOME}/bin/spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE \
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS \
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON \
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE \
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS \
  --conf spark.executorEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON \
  ../advanced/histogram.py
