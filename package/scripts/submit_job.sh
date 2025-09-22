#!/bin/bash

#Source the environment variables to point to the new cluster
set -a
source /spark-submits/source_new_cluster

#The used docker image
IMAGE="vito-docker.artifactory.vgt.vito.be/histogram_sample_package:latest"
#These mounts are required for authentication purposes and for communication between the container and the cluster.
MOUNTS="/var/lib/sss/pipes:/var/lib/sss/pipes:rw,/usr/local/hadoop/:/usr/local/hadoop/:ro,/etc/krb5.conf:/etc/krb5.conf:ro,/data/MTDA/TERRASCOPE_Sentinel2/NDVI_V2/:/data/MTDA/TERRASCOPE_Sentinel2/NDVI_V2/:ro"
#The Python that is installed in the docker container
PYSPARK_PYTHON="/usr/bin/python3.11"

#Parametrize script execution
: "${HISTOGRAM__PROCESSOR_MEMORY:=4G}"
: "${HISTOGRAM__PROCESSOR_EXECUTOR_CORES:=1}"
export HISTOGRAM_PROCESSOR_PARAMETERS="$*"

${SPARK_HOME}/bin/spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --executor-memory=$HISTOGRAM__PROCESSOR_MEMORY \
  --conf spark.executor.cores=$HISTOGRAM__PROCESSOR_EXECUTOR_CORES \
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE \
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS \
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON \
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE \
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS \
  --conf spark.executorEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON \
/usr/local/lib/python3.11/site-packages/histogram_sample_package/histogram.py $HISTOGRAM_PROCESSOR_PARAMETERS
