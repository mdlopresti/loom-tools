# Claude Code Agent - Full Variant
# Adds Claude Code CLI + comprehensive dev tools to runtime image

ARG RUNTIME_IMAGE
FROM ${RUNTIME_IMAGE}

LABEL org.opencontainers.image.description="Loom Agent - Claude Code (Full)"

# Install comprehensive development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    # Version control
    git-lfs \
    # Text processing
    jq \
    yq \
    # Search tools
    ripgrep \
    fd-find \
    fzf \
    # Editors (for git commit editing, etc.)
    vim-tiny \
    # Network tools
    httpie \
    # Archive tools
    zip \
    p7zip-full \
    # Process tools
    htop \
    # Shell utilities
    tree \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

# Install additional Node.js dev tools
RUN npm install -g \
    eslint \
    prettier \
    npm-check-updates \
    && npm cache clean --force

# Required environment variable for Claude
ENV ANTHROPIC_API_KEY=""

# Update capabilities to include claude and dev-tools
ENV AGENT_CAPABILITIES="${AGENT_CAPABILITIES},claude-code,dev-tools"

# Verify installations
RUN claude --version || echo "Claude Code installed" \
    && gh --version \
    && rg --version \
    && jq --version

# Add claude-specific entrypoint wrapper
COPY claude-entrypoint.sh /usr/local/bin/claude-entrypoint.sh
RUN chmod +x /usr/local/bin/claude-entrypoint.sh
