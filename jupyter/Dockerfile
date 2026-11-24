# Layers go from rarely to often changing: students only download changed layers,
# so a JSONiq release is a small update.

FROM ghcr.io/astral-sh/uv:0.13.10 AS uv

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

COPY --from=requirements /src/jsoniq.txt /tmp/
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv pip install --no-deps -r /tmp/jsoniq.txt && uv pip check

# The language server runs with Node.js (from the base image) and downloads
# RumbleDB on first use; fetch it now, outside /home, so it works offline.
ENV JSONIQ_LSP_CACHE_DIR=/opt/jsoniq-lsp
RUN python -m jsoniq_jupyterlab_extension ensure-wrapper

COPY jupyter_server_config.py /etc/jupyter/

# Spark defaults: Delta Lake on in every session without downloads, and
# no Spark logs or progress bars under notebook cells
COPY spark-defaults.conf log4j2.properties /etc/spark/
ENV SPARK_CONF_DIR=/etc/spark

# Default JupyterLab settings: the JSONiq language server uses RumbleDB, with
# Delta Lake on, like the notebooks. Students can change them in Settings.
COPY overrides.json /opt/venv/share/jupyter/lab/settings/
COPY exam-lab-versions /usr/local/bin/

# Shown by exam-lab-versions; CI passes the published tag
ARG IMAGE_VERSION=local-build
ENV EXAM_LAB_VERSION=${IMAGE_VERSION}

WORKDIR /home
CMD ["jupyter", "lab"]
