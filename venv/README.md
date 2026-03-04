# Deploying with Python venv

This method uses Python's standard `venv` tool to manage dependencies. It's a lightweight approach that's excellent for applications that rely on pure-Python packages available from `pip`.

This example uses the `product_job.py` script in the /scripts/ folder.

-----

## Step 1: Create and Pack the Environment

First, create a virtual environment on your local machine and install the necessary packages. Then, use `venv-pack` to create a distributable archive.

```bash
# Create a new virtual environment
python3 -m venv sample_venv

# Activate it
source sample_venv/bin/activate

# Install required packages
pip install pandas venv-pack

# Pack the environment into a tarball
venv-pack -o sample_venv.tar.gz

# Deactivate when done
deactivate
```

This will create a `sample_venv.tar.gz` file.

-----

## Step 2: Submit the Job to YARN

Before submitting, make sure to source the appropriate environment script for your Spark version:
- `source ../scripts/source_new_cluster` - For Spark 3.5.0
- `source ../scripts/source_spark4.sh` - For Spark 4.0.1


You can provide the environment archive to Spark in two ways.

### Option A: Runtime Staging (Simple for a quick test)

This command sends the `sample_venv.tar.gz` file from your local machine along with the job. Configure **`SPARK_VERSION`** for the Spark version you want to use: `3.5.0` or `4.0.1`.

**Manual command** 
(source the right environment first: `source ../scripts/source_new_cluster` for Spark 3.5.0, or `source ../scripts/source_spark4.sh` for Spark 4.0.1).

If `spark-submit` is not found, use `${SPARK_HOME}/bin/spark-submit` instead (the source scripts set `SPARK_HOME`).

```bash
spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --archives sample_venv.tar.gz#environment \
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=./environment/bin/python \
  --conf spark.yarn.executorEnv.PYSPARK_PYTHON=./environment/bin/python \
  ../scripts/product_job.py 500
```

**Example script** (`submit_runtime.sh` in this directory) — it sources the correct cluster config based on `SPARK_VERSION`:

```bash
# Spark 3.5.0 (default)
./submit_runtime.sh

# Spark 4.0.1
SPARK_VERSION=4.0.1 ./submit_runtime.sh
```

### Option B: HDFS Staging (Recommended for efficiency)

Uploading the environment to HDFS once is much faster for repeated job runs.

1.  **Upload the archive to HDFS:**

    ```bash
    kinit
    hdfs dfs -mkdir -p /user/$USER/envs
    hdfs dfs -put -f sample_venv.tar.gz /user/$USER/envs/
    ```

2.  **Submit the job referencing the HDFS path:**

    Configure **`SPARK_VERSION`** (`3.5.0` or `4.0.1`) and source the matching environment, or use the script (see below).

    **Manual command**

    If `spark-submit` is not found, use `${SPARK_HOME}/bin/spark-submit` instead.

    ```bash
    # Submit the job to process 500 products
    spark-submit \
      --master yarn \
      --deploy-mode cluster \
      --archives hdfs:///user/$USER/envs/sample_venv.tar.gz#environment \
      --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=./environment/bin/python \
      --conf spark.yarn.executorEnv.PYSPARK_PYTHON=./environment/bin/python \
      ../scripts/product_job.py 500
    ```

    **Example script:** Use `submit_hdfs.sh` in this directory; it uses the HDFS path and sources the correct cluster config based on `SPARK_VERSION`. Run e.g. `./submit_hdfs.sh` or `SPARK_VERSION=4.0.1 ./submit_hdfs.sh`.