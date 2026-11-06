# Layers go from rarely to often changing: students only download changed layers,
# so a JSONiq or language server release is a small update.

FROM node:24-bookworm-slim AS node

# Split the lock file into JSONiq (released often) and everything else
FROM python:3.11.18-slim-bookworm AS requirements
COPY requirements.txt .
RUN grep '^jsoniq' requirements.txt > jsoniq.txt && grep -v '^jsoniq' requirements.txt > base.txt

FROM python:3.11.18-slim-bookworm
LABEL org.opencontainers.image.description="Jupyter environment for the Big Data exam (Spark, JSONiq, SQL)"

# Java for Spark / RumbleDB
RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Node.js for the language server, copied from the official image
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Python packages except JSONiq (minus the unused 45 MB Spark Connect shell)
COPY --from=requirements base.txt /tmp/
RUN pip install --no-cache-dir --no-deps -r /tmp/base.txt \
    && rm -rf /usr/local/lib/python3.11/site-packages/pyspark/jars/connect-repl

# JSONiq language server. Its ARG is declared here, not at the top, because
# changing an ARG rebuilds every layer below its declaration.
# renovate: datasource=npm depName=jsoniq-language-server
ARG JSONIQ_LS_VERSION=2.18.0
RUN npm i -g jsoniq-language-server@${JSONIQ_LS_VERSION} \
    && npm explore jsoniq-language-server -g -- npm run ensure-wrapper \
    && npm cache clean --force

# JSONiq
COPY --from=requirements jsoniq.txt /tmp/
RUN pip install --no-cache-dir --no-deps -r /tmp/jsoniq.txt && pip check

COPY jupyter_server_config.py /etc/jupyter/
COPY exam-lab-versions /usr/local/bin/

# Shown by exam-lab-versions; CI passes the published tag
ARG IMAGE_VERSION=local-build
ENV EXAM_LAB_VERSION=${IMAGE_VERSION}

WORKDIR /home
CMD ["jupyter", "lab"]
