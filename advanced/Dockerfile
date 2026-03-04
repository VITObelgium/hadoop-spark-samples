FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest

# Define constants
ENV MINICONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-py311_24.7.1-0-Linux-x86_64.sh \
    TMP_DIR=/tmp/build \
    CONDA_DIR=/opt/conda \
    ENV_DIR=/opt/conda/envs/job \
    PATH=/opt/conda/envs/job/bin:$PATH

RUN dnf install -y wget java-17-openjdk-headless \
    && dnf clean all

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# install miniconda and mamba, prevent usage of commercial channels
RUN mkdir $TMP_DIR && \
    wget --quiet $MINICONDA_URL -O $TMP_DIR/miniconda.sh && \
    /bin/bash $TMP_DIR/miniconda.sh -b -p $CONDA_DIR && \
    rm -f $TMP_DIR/miniconda.sh && \
    $CONDA_DIR/bin/conda config --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --remove channels defaults && \
    $CONDA_DIR/bin/conda install -y -q mamba

# install dependencies
COPY environment.yml $TMP_DIR
RUN $CONDA_DIR/bin/mamba create -y -q -f $TMP_DIR/environment.yml && \
    $CONDA_DIR/bin/conda clean -afy