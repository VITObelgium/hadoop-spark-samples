## Deploying with Docker 🐳

This is the **preferred method** for production workloads as it provides the highest level of reproducibility. Your application, Python libraries, and system environment are bundled into a single container image that Spark runs on the cluster.

In this example, we use a **pre-built Docker image** and a submission script that handles all the necessary configurations.

-----

### The Docker Image

The Docker image for this sample is already built and publicly available. You **do not** need to build it yourself.

  * **Image Name:** `vito-docker.artifactory.vgt.vito.be/spark-docker-sample:latest`
  * **Contents:** The image is built from our standard `hadoop-alma9-base` and adds Python 3.11 and the `pandas` library.
  * **Reference `Dockerfile`** (also available in this folder)
    ```dockerfile
    FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest

    RUN dnf install -y python3.11 python3.11-pip \
        && dnf clean all

    RUN pip3.11 install pandas
    ```

-----
### Understanding the `submit.sh` Script

This script automates the process of submitting the Spark job with all the required configurations for a Dockerized environment.

* **`source ...`**: This command loads the environment variables (`SPARK_HOME`, `HADOOP_CONF_DIR`, etc.) required to target the new Hadoop cluster and the correct Spark version.
* **`MOUNTS`**: This variable defines critical volume mounts. It maps files and directories from the host machine (the cluster node) into the Docker container. This is necessary for services like Kerberos (`krb5.conf`) and SSSD (`sss/pipes`) to work correctly, enabling proper authentication inside the container.
* **`PYSPARK_PYTHON`**: This tells Spark the exact path to the Python executable *inside* the container.
* **`spark-submit --conf ...`**: The `--conf` flags pass specific settings to Spark. The following configurations are crucial for running with Docker on YARN.

#### Spark Docker Configurations
These parameters instruct YARN to launch the Spark **Driver** (via `appMasterEnv`) and **Executors** (via `executorEnv`) inside specified Docker containers. Setting them for both ensures a consistent environment for your entire application.

* **`YARN_CONTAINER_RUNTIME_TYPE=docker`** This is the main switch that tells YARN to use the **Docker runtime** for the container. Without this, the process would run directly on the host node's operating system.

* **`YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE`** This specifies **which Docker image** to use for the container. It takes its value from the `$IMAGE` shell variable defined in the script.

* **`YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS`** This defines the **volume mounts**, creating a bridge between the host's filesystem and the container's filesystem.

##### Note on Authenticated Repositories

If your Docker image is stored in a private repository that requires authentication, the cluster nodes need credentials to pull the image. The best practice is to store the Docker configuration file centrally in HDFS.

1.  **Obtain and Upload `config.json`**
    After running `docker login` on a machine, the authentication token is stored in `~/.docker/config.json`. Upload this file to a secure, known location in HDFS.

    ```bash
    # Make a directory in HDFS for auth files
    hdfs dfs -mkdir -p /user/$USER/auth

    # Upload your local docker config
    hdfs dfs -put -f ~/.docker/config.json /user/$USER/auth/config.json
    ```

2.  **Update the `spark-submit` Command**
    You must provide an additional parameter pointing to the HDFS path of the `config.json` file. YARN will handle distributing it to the nodes where tasks are run.

      * **`YARN_CONTAINER_RUNTIME_DOCKER_CLIENT_CONFIG=hdfs:///user/$USER/auth/config.json`**
        You would add this line for both the `appMasterEnv` and `executorEnv` sections. This centralized approach ensures all nodes use the same credentials and makes updating them much easier.