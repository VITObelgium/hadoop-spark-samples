ARG BASE_IMAGE=vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest

FROM ${BASE_IMAGE}
ARG PACKAGE_NAME
#RUN mkdir /etc/pki/ca-trust/extracted/pem
COPY certs/pem /etc/pki/ca-trust/extracted/pem
RUN dnf install -y python3.11 python3.11-pip python3.11-devel gcc make \
    && dnf clean all

COPY dist/${PACKAGE_NAME} /tmp/${PACKAGE_NAME}
RUN pip3.11 install --no-cache-dir /tmp/${PACKAGE_NAME}

COPY scripts /spark-submits
RUN chmod +x /spark-submits/*
