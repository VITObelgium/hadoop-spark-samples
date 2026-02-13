# ---------- Stage 1: Build and pack the conda environment ----------
FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest AS builder

RUN dnf install -y python3.11 python3.11-pip python3.11-devel gcc make \
    && dnf clean all

WORKDIR /app

# Copy project files
COPY pyproject.toml .
COPY . .

# Build wheel
RUN pip3.11 install build
RUN python3.11 -m build --wheel --outdir dist

# ---------- Stage 2: Minimal runtime image ----------
FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest AS runtime

# Install Python only (no dev packages)
RUN dnf install -y python3.11 python3.11-pip \
    && dnf clean all

WORKDIR /app

# Copy the wheel from the builder stage
COPY --from=builder /app/dist/*.whl .

# Install the wheel
RUN pip3.11 install --no-cache-dir ./*.whl

# Copy scripts for Spark submission (supports both Spark 3.5.0 and 4.0.1)
COPY scripts /spark-submits
RUN chmod +x /spark-submits/*