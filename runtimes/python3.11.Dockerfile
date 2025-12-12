# Python 3.11 Runtime Layer
# Built on top of base image

ARG BASE_IMAGE=ghcr.io/mdlopresti/loom-agent-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="Loom Agent - Python 3.11 Runtime"

# Install Python 3.11
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Upgrade pip and install common packages
RUN python -m pip install --upgrade pip setuptools wheel

ENV AGENT_CAPABILITIES=python,python3,python3.11

# Verify installation
RUN python --version && pip --version
