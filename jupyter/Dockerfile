# Layers go from rarely to often changing: students only download changed layers,
# so a JSONiq or language server release is a small update.

FROM ghcr.io/astral-sh/uv:0.13.7 AS uv

# Split the lock per dependency group, so each install layer below only
# changes when its own packages do.
FROM uv AS requirements
WORKDIR /src
COPY pyproject.toml uv.lock ./
RUN ["/uv", "export", "--frozen", "--only-group", "base", "-o", "base.txt"]
RUN ["/uv", "export", "--frozen", "--only-group", "jsoniq", "-o", "jsoniq.txt"]

FROM node:26-trixie-slim
LABEL org.opencontainers.image.description="Jupyter environment for the Big Data exam (Spark, JSONiq, SQL)"

# Java for Spark / RumbleDB
RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-21-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Keep Python and the environment outside /home and the build cache.
ENV UV_PYTHON_INSTALL_DIR=/opt/python
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV UV_LINK_MODE=copy

# Python version from .python-version, shared with local uv commands and Renovate.
COPY .python-version /opt/
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    cd /opt && uv venv --managed-python /opt/venv

# Python packages except JSONiq (minus the unused 45 MB Spark Connect shell)
COPY --from=requirements /src/base.txt /tmp/
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv pip install --no-deps -r /tmp/base.txt \
    && rm -r /opt/venv/lib/python3.*/site-packages/pyspark/jars/connect-repl

# JSONiq language server. Its ARG is declared here, not at the top, because
# changing an ARG rebuilds every layer below its declaration.
# renovate: datasource=npm depName=jsoniq-language-server
ARG JSONIQ_LS_VERSION=2.20.2
RUN npm i -g jsoniq-language-server@${JSONIQ_LS_VERSION} \
    && npm explore jsoniq-language-server -g -- npm run ensure-wrapper \
    && npm cache clean --force

# JSONiq
COPY --from=requirements /src/jsoniq.txt /tmp/
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv pip install --no-deps -r /tmp/jsoniq.txt && uv pip check

COPY jupyter_server_config.py /etc/jupyter/
COPY exam-lab-versions /usr/local/bin/

# Shown by exam-lab-versions; CI passes the published tag
ARG IMAGE_VERSION=local-build
ENV EXAM_LAB_VERSION=${IMAGE_VERSION}

WORKDIR /home
CMD ["jupyter", "lab"]
