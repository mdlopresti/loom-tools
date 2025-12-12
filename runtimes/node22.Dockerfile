# Node.js 22 LTS Runtime Layer
# Built on top of base image

ARG BASE_IMAGE=ghcr.io/mdlopresti/loom-agent-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="Loom Agent - Node.js 22 Runtime"

# Remove Node 20 and install Node 22
RUN apt-get update \
    && apt-get remove -y nodejs \
    && rm -rf /etc/apt/sources.list.d/nodesource.list \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

ENV AGENT_CAPABILITIES=javascript,typescript,nodejs,node22

# Install common Node.js global packages
RUN npm install -g \
    typescript \
    ts-node \
    && npm cache clean --force

# Reinstall Warp with new Node version
RUN npm install -g @loom/warp

# Verify installation
RUN node --version && npm --version && tsc --version
