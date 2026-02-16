## ❗ Important Note: Connecting to the New Hadoop Cluster

We are currently in a transition period from our old Hadoop cluster to a new, upgraded cluster. By default, the `userVM` is configured to interact with the **old** cluster.

To run the examples in this repository against the **new cluster**, you **must** set the following environment variables in your terminal session and/or scripts *before* running any commands.

### For `hdfs` and `yarn` Commands

If you need to interact directly with HDFS or YARN on the new cluster, run these commands first:

```bash
export HADOOP_HOME=/usr/local/hadoop/
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/
export PATH=/usr/local/hadoop/bin/:$PATH
```

### For `spark-submit` Commands

To ensure your Spark jobs are submitted to the new cluster, you must set these variables in addition to the above. The new cluster supports both **Spark 3.5.0** and **Spark 4.0.1**.

**For Spark 3.5.0:**
```bash
export SPARK_HOME=/opt/spark3_5_0/
export SPARK_CONF_DIR=/opt/spark3_5_0/conf2/
```

**For Spark 4.0.1:**
```bash
export SPARK_HOME=/opt/spark4_0_1/
export SPARK_CONF_DIR=/opt/spark4_0_1/conf/
```

**Important:** Spark 4.0.1 requires **Java 17** (class file version 61.0). The `source_spark4.sh` script automatically sets `JAVA_HOME` to `/usr/lib/jvm/java-17-openjdk`. 

To verify that Java 17 is installed and available:
```bash
# Check if Java 17 is installed
ls -d /usr/lib/jvm/java-17-openjdk* 2>/dev/null || echo "Java 17 not found"

# Check Java version
java -version 2>&1 | grep -E "version|openjdk"

# Or check specific Java 17 installation
/usr/lib/jvm/java-17-openjdk/bin/java -version 2>&1 | head -1
```

To make this easier the repository contains source files in the `/scripts/` folder:
- `source_new_cluster` - Sets up environment for Spark 3.5.0
- `source_spark4.sh` - Sets up environment for Spark 4.0.1 (includes Java 17 configuration)

You can source these files directly to set the correct environment variables:
```bash
source scripts/source_new_cluster      # For Spark 3.5.0
# or
source scripts/source_spark4.sh        # For Spark 4.0.1
```

----

# Deploying Python PySpark Applications on Hadoop

This repository provides templates and best practices for deploying PySpark applications with custom Python dependencies onto our Hadoop YARN cluster. Since libraries are not installed globally, you must package your environment with your application.

This guide covers core concepts applicable to all deployment methods and introduces the different strategies you can use.

-----

## Repository Structure

  * `/scripts/`: Folder containing the sample PySpark scripts used in all examples.
  * `/docker/`: A self-contained example for deploying with Docker.
  * `/venv/`: A guide for deploying with Python's `venv`. (For beginners: start here)
  * `/conda/`: A guide for deploying with Conda.
  * `/advanced/`: An integrated example combining docker and conda for raster processing.
  * `/package/`: An integrated example combining docker and a python package for raster processing.

## Dependency Management Approaches

This repository contains examples for the three primary methods of managing dependencies.

1.  **Docker (Preferred)**

      * **What it is:** Your application, Python libraries, and even system-level dependencies are packaged into a container image. YARN runs your job inside these containers.
      * **Why use it:** Provides the highest level of reproducibility and isolation. It's the best way to handle complex dependencies (e.g., those needing system libraries like GDAL). This is the **recommended approach for production workloads**.

2.  **Conda**
      * **What it is:** You use the Conda package manager to create an environment, which is then packed and sent to the cluster.
      * **Why use it:** Excellent for managing complex scientific packages and specific versions of libraries that can be difficult to install with pip.

3.  **Python `venv`**

      * **What it is:** You use Python's built-in, lightweight virtual environment tool.
      * **Why use it:** Great for applications with standard, pure-Python dependencies. It's simple and doesn't require installing Conda.

#### Staging Environments: Runtime vs. HDFS

For both **Conda** and **venv**, you have two options for providing the environment archive to your job:
  * **Runtime Staging:** The archive is uploaded from your local machine with every `spark-submit` command. It's simple but inefficient, as it adds significant network upload time before your job can even start. This should only be used for development.
  * **HDFS Staging (Recommended):** The archive is uploaded to HDFS once. Jobs then reference this HDFS path. This is much faster and more efficient for frequent job runs.

-----
## Prerequisites for deploying to the Hadoop cluster (Kerberos Authentication)
Before interacting with the Hadoop cluster, you must authenticate with Kerberos on your userVM.

Open a terminal and run the kinit command with your username:

    kinit your_username

You can verify your authentication status and ticket details using the klist command:

    klist


## Core Concepts: Managing Partitions

The performance of a Spark job is highly dependent on how data is partitioned. A **partition** is a chunk of your data that a single task will process. The number of partitions determines the degree of parallelism.

#### Too Few, Large Partitions

  * **Problem:** If you only have a few partitions, you won't be using all the available CPU cores on the cluster, leading to low parallelism. Furthermore, if a task fails, the amount of work that needs to be recomputed is very large.
  * **Symptom:** Your job runs slowly, and you see only a few active tasks in the Spark UI.

#### Too Many, Small Partitions

  * **Problem:** Every task has a scheduling overhead. If partitions are too small, the time Spark spends scheduling thousands of tiny tasks can exceed the time spent doing actual work.
  * **Symptom:** The job seems "stuck" with a huge number of tasks, but the overall progress is very slow.

#### Best Practice

Aim to size your partitions so that each task takes from **a few minutes to several minutes** to complete. This makes the scheduling overhead negligible while keeping the cost of re-running a failed task acceptable. The sample scripts in this repository demonstrate 2 different but valid approaches:
1. A single partition per product (when processing a single product takes a longer time) 
2. A batching strategy to batch multiple products per partition. (when processing of a single product takes a small amount of time or when setup/initialization can be shared between products and takes a long time)

-----
