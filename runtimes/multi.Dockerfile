# Multi-Runtime Layer (Node 22 + Python 3.12 + Go 1.22)
# Built on top of base image - for polyglot projects

ARG BASE_IMAGE=ghcr.io/mdlopresti/loom-agent-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="Loom Agent - Multi Runtime (Node 22 + Python 3.12 + Go 1.22)"

# === Node.js 22 ===
RUN apt-get update \
    && apt-get remove -y nodejs \
    && rm -rf /etc/apt/sources.list.d/nodesource.list \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Reinstall Warp with new Node version
RUN npm install -g @loom/warp typescript ts-node \
    && npm cache clean --force

# === Python 3.12 ===
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install pip for Python 3.12
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12 \
    && python -m pip install --upgrade pip setuptools wheel

# === Go 1.22 ===
ARG GO_VERSION=1.22.5
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/root/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# === Combined capabilities ===
ENV AGENT_CAPABILITIES=javascript,typescript,nodejs,node22,python,python3,python3.12,go,golang,go1.22

# Verify installations
RUN node --version && npm --version \
    && python --version && pip --version \
    && go version
