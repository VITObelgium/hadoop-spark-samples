#!/bin/bash
#Source the environment variables to point to the new cluster
# Default to Spark 3.5.0, but allow override via SPARK_VERSION env var
# Set SPARK_VERSION=4.0.1 or SPARK_VERSION=4 to use Spark 4.0.1
set -a
if [ "${SPARK_VERSION:-3.5.0}" = "4.0.1" ] || [ "${SPARK_VERSION:-3.5.0}" = "4" ]; then
    source ../scripts/source_spark4.sh
else
    source ../scripts/source_new_cluster
fi

#The used docker image
IMAGE="vito-docker.artifactory.vgt.vito.be/spark-docker-sample:latest"
#These mounts are required for authentication purposes and for communication between the container and the cluster.
MOUNTS="/var/lib/sss/pipes:/var/lib/sss/pipes:rw,/usr/local/hadoop/:/usr/local/hadoop/:ro,/etc/krb5.conf:/etc/krb5.conf:ro"
#The Python that is installed in the docker container
PYSPARK_PYTHON="/usr/bin/python3.11"

# Add JAVA_HOME config for Spark 4.0.1
SPARK_SUBMIT_ARGS=(
  --master yarn
  --deploy-mode cluster
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE
  --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE
  --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS
  --conf spark.executorEnv.PYSPARK_PYTHON=$PYSPARK_PYTHON
)

# Add JAVA_HOME for Spark 4.0.1
if [ "${SPARK_VERSION:-3.5.0}" = "4.0.1" ] || [ "${SPARK_VERSION:-3.5.0}" = "4" ]; then
  SPARK_SUBMIT_ARGS+=(
    --conf spark.yarn.appMasterEnv.JAVA_HOME=$JAVA_HOME
    --conf spark.executorEnv.JAVA_HOME=$JAVA_HOME
  )
fi

${SPARK_HOME}/bin/spark-submit "${SPARK_SUBMIT_ARGS[@]}" ../scripts/product_job.py 500
