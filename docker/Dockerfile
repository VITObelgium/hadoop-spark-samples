FROM vito-docker.artifactory.vgt.vito.be/hadoop-alma9-base:latest

RUN dnf install -y python3.11 python3.11-pip java-17-openjdk-headless \
    && yum clean all \
    && pip3.11 install pandas

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
