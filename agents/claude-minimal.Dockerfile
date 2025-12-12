# Claude Code Agent - Minimal Variant
# Adds Claude Code CLI to runtime image

ARG RUNTIME_IMAGE
FROM ${RUNTIME_IMAGE}

LABEL org.opencontainers.image.description="Loom Agent - Claude Code (Minimal)"

# Install Claude Code CLI
# Note: Claude Code is installed via npm as @anthropic-ai/claude-code
RUN npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

# Required environment variable for Claude
ENV ANTHROPIC_API_KEY=""

# Update capabilities to include claude
ENV AGENT_CAPABILITIES="${AGENT_CAPABILITIES},claude-code"

# Verify installation
RUN claude --version || echo "Claude Code installed (version check may require API key)"

# Add claude-specific entrypoint wrapper
COPY claude-entrypoint.sh /usr/local/bin/claude-entrypoint.sh
RUN chmod +x /usr/local/bin/claude-entrypoint.sh
