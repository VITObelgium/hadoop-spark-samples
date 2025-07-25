FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest

RUN dnf install -y python3.11 python3.11-pip \
    && yum clean all \
    && pip3.11 install pandas
