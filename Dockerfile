ARG FUNCTION_DIR="/upgrade_function"

FROM amazonlinux:2
RUN  yum -y update && \
    yum -y install wget gzip tar zip && \
    yum clean all

FROM python:3.12 AS build-image

ARG FUNCTION_DIR

RUN mkdir -p ${FUNCTION_DIR}
COPY requirements.txt .

COPY . ${FUNCTION_DIR}

RUN pip install --target ${FUNCTION_DIR} awslambdaric

# Install the specified packages
RUN pip install -r requirements.txt --target ${FUNCTION_DIR} 

# install maven
ARG MAVEN_VERSION=3.9.12
ARG USER_HOME_DIR="/root"

 RUN wget https://dlcdn.apache.org/maven/maven-3/3.9.12/binaries/apache-maven-3.9.12-bin.tar.gz -P /tmp && \
    tar -xzf /tmp/apache-maven-3.9.12-bin.tar.gz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    rm /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz


FROM python:3.12-slim

COPY --from=amazoncorretto:17 /usr/lib/jvm/java-17-amazon-corretto /usr/lib/jvm/java-17-amazon-corretto

# Set Java and Maven environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
ENV MAVEN_HOME=/opt/maven
ENV PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
CMD ["lambda_handler.lambda_handler"]


