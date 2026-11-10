# Install the base and JSONiq dependency groups in separate steps.
# Both use the same lock file, so lock changes invalidate the base install too.

FROM node:24-bookworm-slim AS node
FROM ghcr.io/astral-sh/uv:0.13.7 AS uv

FROM python:3.11.15-slim-bookworm
LABEL org.opencontainers.image.description="Jupyter environment for the Big Data exam (Spark, JSONiq, SQL)"

# Java for Spark / RumbleDB
RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Node.js for the language server, copied from the official image
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Keep the environment outside /home, where notebooks are mounted.
ENV UV_PROJECT_ENVIRONMENT=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /opt/exam-lab
COPY pyproject.toml uv.lock ./

# Install the base group directly from the lock; fail if it is out of date.
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --only-group base --link-mode=copy \
    && rm -rf /opt/venv/lib/python3.11/site-packages/pyspark/jars/connect-repl

# JSONiq language server. Its ARG is declared here, not at the top, because
# changing an ARG rebuilds every layer below its declaration.
# renovate: datasource=npm depName=jsoniq-language-server
ARG JSONIQ_LS_VERSION=2.18.0
RUN npm i -g jsoniq-language-server@${JSONIQ_LS_VERSION} \
    && npm explore jsoniq-language-server -g -- npm run ensure-wrapper \
    && npm cache clean --force

# Include both groups so the final sync retains the base packages.
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-default-groups --group base --group jsoniq --link-mode=copy \
    && uv pip check --python /opt/venv/bin/python

COPY jupyter_server_config.py /etc/jupyter/
COPY exam-lab-versions /usr/local/bin/

# Shown by exam-lab-versions; CI passes the published tag
ARG IMAGE_VERSION=local-build
ENV EXAM_LAB_VERSION=${IMAGE_VERSION}

WORKDIR /home
CMD ["jupyter", "lab"]
