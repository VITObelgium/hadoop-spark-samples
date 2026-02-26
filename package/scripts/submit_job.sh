#!/bin/bash

# Source the environment for the cluster and Spark version.
# Works both when run on the host (from package/scripts/) and in the container (from /spark-submits/).
# Default: Spark 3.5.0. Set SPARK_VERSION=4.0.1 or SPARK_VERSION=4 for Spark 4.0.1.
set -a
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "${SPARK_VERSION:-3.5.0}" = "4.0.1" ] || [ "${SPARK_VERSION:-3.5.0}" = "4" ]; then
    source "$SCRIPT_DIR/source_spark4.sh"
else
    source "$SCRIPT_DIR/source_new_cluster"
fi

#The used docker image 
IMAGE="vito-docker.artifactory.vgt.vito.be/histogram_sample_package:2026.2.26" #Override the latest tag with specific version
#These mounts are required for authentication purposes and for communication between the container and the cluster.
MOUNTS="/var/lib/sss/pipes:/var/lib/sss/pipes:rw,/usr/local/hadoop/:/usr/local/hadoop/:ro,/etc/krb5.conf:/etc/krb5.conf:ro,/data/MTDA/TERRASCOPE_Sentinel2/NDVI_V2/:/data/MTDA/TERRASCOPE_Sentinel2/NDVI_V2/:ro"
#The Python that is installed in the docker container
PYSPARK_PYTHON="/usr/bin/python3.11"

#Parametrize script execution
: "${HISTOGRAM__PROCESSOR_MEMORY:=4G}"
: "${HISTOGRAM__PROCESSOR_EXECUTOR_CORES:=1}"
export HISTOGRAM_PROCESSOR_PARAMETERS="$*"

# Build spark-submit arguments
SPARK_SUBMIT_ARGS=(
  --master yarn
  --deploy-mode cluster
  --executor-memory=$HISTOGRAM__PROCESSOR_MEMORY
  --conf spark.executor.cores=$HISTOGRAM__PROCESSOR_EXECUTOR_CORES
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON
  --conf spark.yarn.appMasterEnv.JAVA_HOME=/usr/lib/jvm/jre-17
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS
  --conf spark.executorEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON
  --conf spark.executorEnv.JAVA_HOME=/usr/lib/jvm/jre-17
)


${SPARK_HOME}/bin/spark-submit "${SPARK_SUBMIT_ARGS[@]}" /usr/local/lib/python3.11/site-packages/histogram_sample_package/histogram.py $HISTOGRAM_PROCESSOR_PARAMETERS
