#!/bin/sh
export SPARK_HOME=/opt/spark3_5_0/
export SPARK_CONF_DIR=/opt/spark3_5_0/conf2/
export HADOOP_HOME=/usr/local/hadoop/
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/
export PATH=/usr/local/hadoop/bin/:$PATH

${SPARK_HOME}/bin/spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --archives sample_venv.tar.gz#environment \
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=./environment/bin/python \
  --conf spark.yarn.executorEnv.PYSPARK_PYTHON=./environment/bin/python \
  ../scripts/product_job.py 500