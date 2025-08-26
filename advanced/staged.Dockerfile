# ---------- Stage 1: Build and pack the conda environment ----------
FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest AS builder

# Define constants
ENV MINICONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-py311_24.7.1-0-Linux-x86_64.sh \
    CONDA_DIR=/opt/conda \
    TMP_DIR=/tmp/build \
    ENV_DIR=$CONDA_DIR/envs/job

# install miniconda and mamba, prevent usage of commercial conda channels
RUN set -eux \
    && dnf install -y wget && dnf clean all \
    && mkdir -p $TMP_DIR \
    && wget --quiet $MINICONDA_URL -O "$TMP_DIR/miniconda.sh" \
    && bash $TMP_DIR/miniconda.sh -b -p "$CONDA_DIR" \
    && $CONDA_DIR/bin/conda config --add channels conda-forge \
    && $CONDA_DIR/bin/conda config --remove channels defaults \
    && $CONDA_DIR/bin/conda install -y -q mamba conda-pack

# create the environment form the yml file and pack it
COPY environment.yml $TMP_DIR/
RUN set -eux \
    && $CONDA_DIR/bin/mamba env create -f "$TMP_DIR/environment.yml" \
    && $CONDA_DIR/bin/conda-pack -p $ENV_DIR -o /tmp/env.tar

# ---------- Stage 2: Minimal runtime image ----------
FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest

# Set environment path so the environment's binaries are default
ENV ENV_DIR=/opt/env \
    PATH=/opt/env/bin:$PATH \
    # GDAL_DATA gets unset when using multistage builds
    GDAL_DATA=/opt/env/share/gdal

# Copy only the packed environment from builder stage
COPY --from=builder /tmp/env.tar /tmp/env.tar

RUN set -eux \
    # Create target environment directory
    && mkdir -p $ENV_DIR \
    # Extract environment into target dir
    && tar -xf /tmp/env.tar -C $ENV_DIR \
    # Remove tarball to save space
    && rm -f /tmp/env.tar