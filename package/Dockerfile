ARG BASE_IMAGE=vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest

FROM ${BASE_IMAGE}
ARG PACKAGE_NAME

RUN dnf install -y python3.11 python3.11-pip python3.11-devel gcc make java-17-openjdk-headless \
    && dnf clean all


COPY dist/${PACKAGE_NAME} /tmp/${PACKAGE_NAME}
RUN pip3.11 install --no-cache-dir /tmp/${PACKAGE_NAME}

COPY scripts /spark-submits
RUN chmod +x /spark-submits/*
