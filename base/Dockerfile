# Base image with Warp MCP server and essential tools
# This is the foundation for all loom-agent images

FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/mdlopresti/loom-agent-images"
LABEL org.opencontainers.image.description="Loom Agent Base Image"
LABEL org.opencontainers.image.licenses="MIT"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    openssh-client \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS (required for Warp)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Warp MCP server from GitHub releases
ARG WARP_VERSION=latest
RUN if [ "$WARP_VERSION" = "latest" ]; then \
        WARP_VERSION=$(curl -s https://api.github.com/repos/mdlopresti/loom-warp/releases/latest | grep tag_name | cut -d'"' -f4); \
    fi \
    && npm install -g @loom/warp@${WARP_VERSION#v} || npm install -g @loom/warp

# Create workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Set up entrypoint script location
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default environment variables
ENV NATS_URL=nats://localhost:4222
ENV PROJECT_ID=default
ENV AGENT_CAPABILITIES=general

# Health check - verify warp is installed
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD which warp || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
