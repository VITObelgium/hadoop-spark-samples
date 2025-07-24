
# Deploying with Conda

This method uses the Conda package manager to create and package your application's environment. It's particularly strong for managing complex scientific packages and their binary dependencies.

This example uses the `product_job.py` script in the /scripts/ folder.

-----

## Step 1: Create and Pack the Environment

First, create a Conda environment on your local machine and install the necessary packages. Then, use `conda-pack` to create a distributable archive.

```bash
# Create a new conda environment
conda create -n sample_conda_env python=3.11 pandas -y

# Activate it
conda activate sample_conda_env

# Install conda-pack
conda install -c conda-forge conda-pack

# Pack the environment into a tarball
conda pack -o sample_conda_env.tar.gz

# Deactivate when done
conda deactivate
```

This will create a `sample_conda_env.tar.gz` file.

-----

## Step 2: Submit the Job to YARN

You can provide the environment archive to Spark in two ways.

### Option A: Runtime Staging (Simple for a quick test)

This command sends the `sample_conda_env.tar.gz` file from your local machine along with the job.

```bash
# Submit the job to process 500 products
spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --archives sample_conda_env.tar.gz#environment \
  --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=./environment/bin/python \
  --conf spark.yarn.executorEnv.PYSPARK_PYTHON=./environment/bin/python \
  product_job.py 500
```

### Option B: HDFS Staging (Recommended for efficiency)

Uploading the environment to HDFS once is much faster for repeated job runs.

1.  **Upload the archive to HDFS:**

    ```bash
    hdfs dfs -mkdir -p /user/$USER/envs
    hdfs dfs -put -f sample_conda_env.tar.gz /user/$USER/envs/
    ```

2.  **Submit the job referencing the HDFS path:**

    ```bash
    # Submit the job to process 500 products
    spark-submit \
      --master yarn \
      --deploy-mode cluster \
      --archives hdfs:///user/$USER/envs/sample_conda_env.tar.gz#environment \
      --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=./environment/bin/python \
      --conf spark.yarn.executorEnv.PYSPARK_PYTHON=./environment/bin/python \
      product_job.py 500
    ```