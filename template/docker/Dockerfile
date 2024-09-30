# Define argument

ARG IMAGE_VERSION="3.12.1-slim-bullseye"

ARG PYTHON_HOME=""



#############################################################################
# Base stage
#############################################################################

FROM python:${IMAGE_VERSION} as base-stage

LABEL maintainer="hy2" \
    version="1.0" \
    description="This image is test image for test."
# LABEL maintainer="hy2" version="1.0" description="This image is test image for test."

ARG 

RUN mkdir -r /app
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential

WORKDIR /app/test


#############################################################################
# Build stage
#############################################################################
FROM base-stage as build-stage


RUN 


RUN pip wheel --wheel-dir ${PYTHON_WHEEL_PATH} poetry==${POETRY_VERSION} \
    && pip wheel --wheel-dir ${PYTHON_WHEEL_PATH} psycopg2==${PSYCOPG2_VERSION} \
    && pip install --no-cache-dir --no-index --find-links=${PYTHON_WHEEL_PATH} ${PYTHON_WHEEL_PATH}/poetry* \
    && pip install --no-cache-dir --no-index --find-links=${PYTHON_WHEEL_PATH} ${PYTHON_WHEEL_PATH}/psycopg2*







#############################################################################
# Run Stage
#############################################################################
FROM base-stage as run-stage


EXPOSE 80/tcp 
# EXPOSE 80/udp

# VOLUME ["/data", "/shared"] or docker run -itd -v /host/some/where:/container/some/where ubuntu

ENV PYTHON_PATH="/var" PYTHON_HOME="/var"

ARG PYTHON_VERSION="3.8"



RUN groupadd -r postgres && useradd --no-log-init -r -g postgres postgres

# --build-arg PYTHON_VERSION=


# ADD --checksum=sha256:270d731bd08040c6a3228115de1f74b91cf441c584139ff8f8f6503447cebdbb \
#    https://dotnetcli.azureedge.net/dotnet/Runtime/$DOTNET_VERSION/dotnet-runtime-$DOTNET_VERSION-linux-arm64.tar.gz /dotnet.tar.gz


ONBUILD COPY website.tar /var/www/html/
COPY --chown=toram:toram *.txt /toramko/
# COPY requirements.txt /tmp/requirements.txt
RUN --mount=type=bind,source=requirements.txt,target=/tmp/requirements.txt \
    pip install --requirement /tmp/requirements.txt


RUN apt-get update && apt-get install -y \
  bzr \
  cvs \
  git \
  mercurial \
  subversion \
  && rm -rf /var/lib/apt/lists/*
RUN wget -O - https://some.site | wc -l > /number

ENTRYPOINT ["/bin/bash", "-c", "echo hello $H_NAME"]
# CMD ["postgres"]
