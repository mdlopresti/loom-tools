# Python 3.12 Runtime Layer
# Built on top of base image

ARG BASE_IMAGE=ghcr.io/mdlopresti/loom-agent-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="Loom Agent - Python 3.12 Runtime"

# Add deadsnakes PPA for Python 3.12
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
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

# Upgrade pip and install common packages
RUN python -m pip install --upgrade pip setuptools wheel

ENV AGENT_CAPABILITIES=python,python3,python3.12

# Verify installation
RUN python --version && pip --version
