
# Remote sensing data processing

This sample builds on the [conda](../conda/README.md) and [docker](../docker/README.md) samples to provide an integrated
example of raster data processing.

-----

## Step 1: Create the Spark job

There are several parts of the eventual spark job that need to be created.

### Define the environment
The python version and dependencies can be configured to the `requirements.yml` file. 
This file is copied to the docker image during the build to create a conda environment.
The name of the environment is `job`. If you change this you also need to change the `ENV_DIR` in the Dockerfile.
Make sure to update `PYSPARK_PYTHON` in `submit_job.sh` to reference the correct python version.

### Write the processing logic
The python spark job uses the specified dependencies to create a simple data processing workflow.
It takes a set of raster files matching filter conditions and distributes the calculation a histogram of all pixel values.

The main `histogram.py` file defines the high level flow and will be the starting point of the spark job.
Additional functionality is defined in `utilities/functions.py` to demonstrate how to keep more complex logic organized.
The `utilities` folder is zipped and deployed with the application to make it available on all nodes.

### Create a docker image
We use docker to deploy our conda environment to the Hadoop cluster, as this greatly simplifies dependency management.
We provide two docker files in this sample to highlight best practices concerning the creation of docker images.

#### Standard Dockerfile
In the basic `Dockerfile` we take the dependencies as defined in `requirements.yml` and use conda to build a 
corresponding python environment. This environment is then made available via `PATH` so that any spark job that runs 
in the container has access to the correct dependencies.

#### Staged Dockerfile
Building a conda environment in the image introduces a large amount of supporting files that are actually not
needed to run the environment itself. This increases the size of the docker image considerably, 
which slows down job startup and puts additional strain on the cluster network.

Docker solves this with [multi-stage builds](https://docs.docker.com/build/building/multi-stage/). 
This introduces the concept of an intermediary docker image in which we can prepare the conda environment during a build. 
We can then just take the bits we need from this intermediary image and put them in the final image. 
An example of this procedure can be found in `staged.Dockerfile`.

In `staged.Dockerfile` we define a `builder` stage where we install conda, take the `requirements.yml` and create the conda env. 
This is the same procedure as in the standard `Dockerfile`. However now we use `conda-pack` to bundle the entire conda environment into a tarfile.
We then start build of the actual output dokcer image. There we only copy the tar file from the `builder` stage and unpack it.
No other actions are needed except to add python to the `PATH`, not even conda is installed.

#### Best practice
We recommend using multi-stage docker builds to keep the resulting images small. 
In this case for example there is a 2gb difference between the staged and non-staged images.

### Deploy docker image to repository
You can add your own images to a publicly accessible registry of your choice.
Check the documentation of the [docker](../docker/README.md) sample to learn how to make your repository available 
in the Hadoop cluster.

The sample image defined here is already available from the public 
`vito-docker.artifactory.vgt.vito.be/spark-docker-sample-advanced` repository with the `latest` tag.
The image includes Java 17 and supports both Spark 3.5.0 and Spark 4.0.1.

-----

## Step 2: Submit the Job to YARN
We use the `submit_job.sh` script to run the spark job on the cluster.
Refer to the [docker sample](../docker/README.md) for more information about submitting jobs in with docker images.

**Note:** The `submit_job.sh` script sources `../scripts/source_new_cluster` by default (for Spark 3.5.0). To use Spark 4.0.1, you can modify the script to source `../scripts/source_spark4.sh` instead, or set the environment variables manually before running the script.

**Important:** Spark 4.0.1 requires Java 17. The `source_spark4.sh` script automatically configures `JAVA_HOME` to Java 17. Ensure Java 17 is available on cluster nodes. Verify with:
  ```bash
  ls -d /usr/lib/jvm/java-17-openjdk* 2>/dev/null && echo "Java 17 found" || echo "Java 17 not found"
  /usr/lib/jvm/java-17-openjdk/bin/java -version 2>&1 | head -1
  ```

An important difference here is the inclusion of `/data/MTDA/TERRASCOPE_Sentinel2/NDVI_V2/` in the mounts, as we need access to the data stored there.
We also add the zipped dependencies of the spark job.

The output of the job can be found in the spark application logs.

Some things to keep in mind:

- Make sure to use `PYSPARK_PYTHON` to refer to the python version specified in `requirements.yml`.
- Zip any dependencies you have and include them in the `spark-submit` command.
  - Take note of the zipped folder structure, as it will mirror the path you give in the zip command
- Point `IMAGE` to the correct repository and make sure it is reachable from the cluster.
- Add any volumes you need to the `MOUNTS` variable
