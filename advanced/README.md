
# Remote sensing data processing

This sample builds on the [conda](../conda/README.md) and [docker](../docker/README.md) samples to integrate all parts and introduce the processing of remote sensing data.

-----

## Step 1: Create the application

There are several parts of the eventual spark job that need to be created.

### Define the environment
The python version and dependencies can be configured to the `requirements.yml` file. 
This file is copied to the docker image during the build to create a conda environment.
The name of the environment is `job`. If you change this you also need to change the `PATH` in the Dockerfile.
Make sure to update `PYSPARK_PYTHON` in `submit_job.sh` to reference the correct python version.

### Write the processing logic
The python spark job uses the specified dependencies to create a simple data processing workflow.
It takes a set of raster files matching filter conditions and distributes the calculation a histogram of all pixel values.

The main `histogram.py` file defines the high level flow and will be the starting point of the spark job.
Additional functionality is defined in `utilities/functions.py` to demonstrate how to keep more complex logic organized.
The `utilities` folder is zipped and deployed with the application to make it available on all nodes.

### Create a docker image
The docker image uses the same base image as in the `docker` sample.
We create a conda environment based on the `requirements.yml`.
Because conda installs its own python, we do nor need to provide it ourselves.

### Deploy docker image to repository

-----

## Step 2: Submit the Job to YARN
We use the `submit_job.sh` script to run the spark job on the cluster. 
Refer to the [docker sample](../docker/README.md) for more information about submitting jobs in with docker images.

Some things to keep in mind:

- Make sure to use `PYSPARK_PYTHON` to refer to the python version specified in `requirements.yml`.
- Point `IMAGE` to the correct repository and make sure it is reachable from the cluster.