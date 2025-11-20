FROM node:24 AS frontend-builder

COPY ./maubot/management/frontend /frontend
RUN cd /frontend && yarn --prod && yarn build


# ---------------------------------------------
# Python image instead of Alpine
# ---------------------------------------------
FROM python:3.12-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Install correct yq (Go version)
RUN wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gosu \
    git \
    build-essential \
    libffi-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    zlib1g-dev \
    libmagic1 \
    libolm3 \
    libolm-dev \
    && rm -rf /var/lib/apt/lists/*
# ---------------------------------------------
# Install Python deps
# ---------------------------------------------
COPY requirements.txt /opt/maubot/requirements.txt
COPY optional-requirements.txt /opt/maubot/optional-requirements.txt

WORKDIR /opt/maubot

# Install build deps temporarily
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
        python3-dev \
    && pip install --no-cache-dir --break-system-packages \
        -r requirements.txt \
        -r optional-requirements.txt \
        dateparser langdetect python-gitlab pyquery tzlocal \
    && apt-get purge -y gcc python3-dev \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# Copy application
# ---------------------------------------------
COPY . /opt/maubot
RUN cp maubot/example-config.yaml .
COPY ./docker/mbc.sh /usr/local/bin/mbc
COPY --from=frontend-builder /frontend/build /opt/maubot/frontend

ENV UID=1337 GID=1337 XDG_CONFIG_HOME=/data
VOLUME /data

CMD ["/opt/maubot/docker/run.sh"]
