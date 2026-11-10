# Install the base and JSONiq dependency groups in separate steps.
# Both use the same lock file, so lock changes invalidate the base install too.

FROM ghcr.io/astral-sh/uv:0.13.7 AS uv

FROM node:24-bookworm-slim
LABEL org.opencontainers.image.description="Jupyter environment for the Big Data exam (Spark, JSONiq, SQL)"

# Java for Spark / RumbleDB
RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Keep Python and the environment outside /home and the build cache.
ENV UV_PYTHON_INSTALL_DIR=/opt/python
ENV UV_PROJECT_ENVIRONMENT=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /opt/exam-lab

# Install the exact version shared with local uv commands and Renovate.
COPY .python-version ./
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv python install --no-bin

COPY pyproject.toml uv.lock ./

# Install the base group directly from the lock; fail if it is out of date.
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --only-group base --link-mode=copy

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
