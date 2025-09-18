
# Remote sensing data processing

This sample combines the [docker](../docker/README.md) sample and python packages to provide an integrated example of raster data processing. 

-----

## Step 1: Create the Spark job

There are several parts of the eventual spark job that need to be created.

### Define the package
We follow modern standards by using a `pyproject.toml` file to configure our package. 
You can copy the content and modify it to suit your own needs. 
Additional information can be found [here](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/).
Building the package locally can be done by running `python -m build` in the folder containing `pyproject.toml`.

### Write the processing logic
The python spark job uses the specified dependencies to create a simple data processing workflow.
It takes a set of raster files matching filter conditions and distributes the calculation a histogram of all pixel values.

The `histogram.py` file defines the high level flow and will be the starting point of the spark job.
All logic is contained in the `/histogram_sample_package` folder, which will be bundled into a python package.
This allows other users to easily integrate it into their pipelines, simply by pip installing and then importing it.

### Create a docker image
We use docker to deploy our package to the Hadoop cluster, as this greatly simplifies dependency management.
We provide two docker files in this sample to highlight best practices concerning the creation of docker images.

#### Standard Dockerfile
In the basic `Dockerfile` we copy a prebuilt wheel and install it in the docker image.
The only requirement is to pass the wheel name to the build command: 
`docker build --build-arg PACKAGE_NAME=<filename>.whl spark_sample:latest .`

This integrates well with CI/CD where the wheel is built as a different step in the pipeline.

#### Staged Dockerfile
Building a python environment in the image introduces a large amount of supporting files that are actually not
needed to run the environment itself. This increases the size of the docker image considerably, 
which slows down job startup and puts additional strain on the cluster network.

Docker solves this with [multi-stage builds](https://docs.docker.com/build/building/multi-stage/). 
This introduces the concept of an intermediary docker image in which we can prepare the wheel during a build. 
We can then just take the bits we need from this intermediary image and put them in the final image. 
An example of this procedure can be found in `staged.Dockerfile`.

In `staged.Dockerfile` we define a `builder` stage where we create a wheel from the `histogram_sample_package` based on the `pyproject.toml` file.
We then start build of the actual output dokcer image. There we only copy the tar file from the `builder` stage and install it.
This method is better suited for creating images locally.

### Deployment
#### Deploy docker image to repository manually
You can add your own images to a publicly accessible registry of your choice.
Check the documentation of the [docker](../docker/README.md) sample to learn how to make your repository available 
in the Hadoop cluster.

The sample image defined here is already available from the public 
`vito-docker.artifactory.vgt.vito.be/spark-docker-sample-advanced`repository with the `latest` tag.

#### Deploy via automated CI/CD pipeline
This sample also contains a `Jenkinsfile` where we define an automated way to build, 
test and deploy the logic via the internal Vito build infrastructure. We have configured it to deploy the image 
based on the `Dockerfile` to be deployed to the vito-docker.artifactory.vgt.vito.be.
There the image will be available as `histogram_sample_package:latest` and `histogram_sample_package:2025.09.01`.

-----

## Step 2: Submit the Job to YARN
We use the `scipts/submit_job.sh` script to run the spark job on the cluster.
Refer to the [docker sample](../docker/README.md) for more information about submitting jobs in with docker images.
An important difference here is the inclusion of `/data/MTDA/TERRASCOPE_Sentinel2/NDVI_V2/` in the mounts, as we need access to the data stored there.

As the `submit_job.sh` script is included in the docker image, we can run spark jobs directly from the docker image.
This is done using

``shell
docker run 
    -e HISTOGRAM__PROCESSOR_MEMORY=8gb 
    -e HISTOGRAM__PROCESSOR_EXECUTOR_CORES=2 
    vito-docker.artifactory.vgt.vito.be/spark-docker-sample-advanced:latest
    /spark_submits/submit_job.sh
    --start_date=2024-05-01
``

The output of the job can be found in the spark application logs.

Some things to keep in mind:

- Make sure to use `PYSPARK_PYTHON` to refer to the python version specified in the docker image.
- Point `IMAGE` to the correct repository and make sure it is reachable from the cluster.
- Add any volumes you need to the `MOUNTS` variable
