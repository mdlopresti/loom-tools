# Node.js 20 LTS Runtime Layer
# Built on top of base image

ARG BASE_IMAGE=ghcr.io/mdlopresti/loom-agent-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="Loom Agent - Node.js 20 Runtime"

# Node 20 is already installed in base image for Warp
# Just verify and set capabilities

ENV AGENT_CAPABILITIES=javascript,typescript,nodejs,node20

# Install common Node.js global packages
RUN npm install -g \
    typescript \
    ts-node \
    && npm cache clean --force

# Verify installation
RUN node --version && npm --version && tsc --version
