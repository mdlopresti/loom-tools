# Unified Dockerfile for Loom Agent Images
# Builds any combination of agent + runtime + variant using build args
#
# Build args:
#   AGENT: claude (default), copilot, aider
#   RUNTIME: node20 (default), node22, python3.11, python3.12, multi
#   VARIANT: minimal (default), full
#
# Example:
#   docker build --build-arg AGENT=claude --build-arg RUNTIME=node22 --build-arg VARIANT=full -t loom-agent:claude-node22-full .

ARG AGENT=claude
ARG RUNTIME=node20
ARG VARIANT=minimal

# =============================================================================
# Stage 1: Base image with Warp
# =============================================================================
FROM ubuntu:22.04 AS base

LABEL org.opencontainers.image.source="https://github.com/mdlopresti/loom-agent-images"
LABEL org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Essential system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    openssh-client \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 (required for Warp, may be upgraded in runtime stage)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Warp MCP server from git
# Note: @loom/warp will be available on npm after Dec 16, 2024
# Until then, we clone, build, pack, and install the tarball
ARG WARP_VERSION=v0.1.1
RUN git clone --depth 1 --branch ${WARP_VERSION} https://github.com/mdlopresti/loom-warp.git /tmp/warp \
    && cd /tmp/warp \
    && npm install \
    && npm run build \
    && npm pack \
    && npm install -g ./loom-warp-*.tgz \
    && cd / \
    && rm -rf /tmp/warp \
    && npm cache clean --force

WORKDIR /workspace

# =============================================================================
# Stage 2: Runtime variants
# =============================================================================

# --- Node.js 20 (default, already in base) ---
FROM base AS runtime-node20
ENV AGENT_CAPABILITIES=javascript,typescript,nodejs,node20
RUN npm install -g typescript ts-node && npm cache clean --force

# --- Node.js 22 ---
FROM base AS runtime-node22
ENV AGENT_CAPABILITIES=javascript,typescript,nodejs,node22
ARG WARP_VERSION=v0.1.1
RUN apt-get update \
    && apt-get remove -y nodejs \
    && rm -rf /etc/apt/sources.list.d/nodesource.list \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*
# Reinstall Warp with Node 22
RUN git clone --depth 1 --branch ${WARP_VERSION} https://github.com/mdlopresti/loom-warp.git /tmp/warp \
    && cd /tmp/warp && npm install && npm run build && npm pack && npm install -g ./loom-warp-*.tgz \
    && cd / && rm -rf /tmp/warp \
    && npm install -g typescript ts-node \
    && npm cache clean --force

# --- Python 3.11 ---
FROM base AS runtime-python3.11
ENV AGENT_CAPABILITIES=python,python3,python3.11
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && python -m pip install --upgrade pip setuptools wheel

# --- Python 3.12 ---
FROM base AS runtime-python3.12
ENV AGENT_CAPABILITIES=python,python3,python3.12
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12 \
    && python -m pip install --upgrade pip setuptools wheel

# --- Multi (Node 22 + Python 3.12 + Go 1.22) ---
FROM base AS runtime-multi
ENV AGENT_CAPABILITIES=javascript,typescript,nodejs,node22,python,python3,python3.12,go,golang
ARG WARP_VERSION=v0.1.1
# Node 22
RUN apt-get update \
    && apt-get remove -y nodejs \
    && rm -rf /etc/apt/sources.list.d/nodesource.list \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*
# Reinstall Warp with Node 22
RUN git clone --depth 1 --branch ${WARP_VERSION} https://github.com/mdlopresti/loom-warp.git /tmp/warp \
    && cd /tmp/warp && npm install && npm run build && npm pack && npm install -g ./loom-warp-*.tgz \
    && cd / && rm -rf /tmp/warp \
    && npm install -g typescript ts-node \
    && npm cache clean --force
# Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3.12-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12 \
    && python -m pip install --upgrade pip setuptools wheel
# Go 1.22
RUN curl -fsSL https://go.dev/dl/go1.22.5.linux-amd64.tar.gz | tar -C /usr/local -xzf -
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"
ENV GOPATH="/root/go"

# =============================================================================
# Stage 3: Select runtime based on build arg
# =============================================================================
ARG RUNTIME
FROM runtime-${RUNTIME} AS runtime-selected

# =============================================================================
# Stage 4: Variant layers (minimal vs full)
# =============================================================================

# --- Minimal variant (just essentials) ---
FROM runtime-selected AS variant-minimal
# No additional packages needed

# --- Full variant (comprehensive dev tools) ---
FROM runtime-selected AS variant-full
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git-lfs \
    jq \
    ripgrep \
    fd-find \
    fzf \
    vim-tiny \
    httpie \
    zip \
    p7zip-full \
    htop \
    tree \
    && rm -rf /var/lib/apt/lists/*
# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*
# Additional Node tools (if node available)
RUN which npm && npm install -g eslint prettier npm-check-updates && npm cache clean --force || true

# =============================================================================
# Stage 5: Select variant based on build arg
# =============================================================================
ARG VARIANT
FROM variant-${VARIANT} AS variant-selected

# =============================================================================
# Stage 6: Agent layers
# =============================================================================

# --- Claude Code ---
FROM variant-selected AS agent-claude
ENV ANTHROPIC_API_KEY=""
RUN npm install -g @anthropic-ai/claude-code && npm cache clean --force
# Note: claude --version requires API key, so we just verify the binary exists
RUN which claude

# --- Copilot CLI (placeholder for future) ---
FROM variant-selected AS agent-copilot
# TODO: Add GitHub Copilot CLI installation when available
RUN echo "Copilot CLI agent - coming soon"

# --- Aider (placeholder for future) ---
FROM variant-selected AS agent-aider
# TODO: Add Aider installation
RUN echo "Aider agent - coming soon"

# =============================================================================
# Stage 7: Final image - select agent based on build arg
# =============================================================================
ARG AGENT
FROM agent-${AGENT} AS final

# Re-declare build args for labels
ARG AGENT
ARG RUNTIME
ARG VARIANT

LABEL org.opencontainers.image.description="Loom Agent - ${AGENT} / ${RUNTIME} / ${VARIANT}"

# Copy entrypoint scripts
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/claude-wrapper.sh /usr/local/bin/claude-wrapper.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/claude-wrapper.sh

# Default environment variables
ENV NATS_URL=nats://localhost:4222
ENV PROJECT_ID=default
ENV LOOM_AGENT=${AGENT}
ENV LOOM_RUNTIME=${RUNTIME}
ENV LOOM_VARIANT=${VARIANT}

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
