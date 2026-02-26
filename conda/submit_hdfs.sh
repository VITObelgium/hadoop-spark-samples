#!/bin/bash
# Source the environment for the chosen Spark version.
# Default: Spark 3.5.0. Set SPARK_VERSION=4.0.1 or SPARK_VERSION=4 for Spark 4.0.1.
set -a
if [ "${SPARK_VERSION:-3.5.0}" = "4.0.1" ] || [ "${SPARK_VERSION:-3.5.0}" = "4" ]; then
    source ../scripts/source_spark4.sh
else
    source ../scripts/source_new_cluster
fi

${SPARK_HOME}/bin/spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --archives hdfs:///user/$USER/envs/sample_conda_env.tar.gz#environment \
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=./environment/bin/python \
  --conf spark.yarn.executorEnv.PYSPARK_PYTHON=./environment/bin/python \
  ../scripts/product_job.py 500
