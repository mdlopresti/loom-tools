#!/bin/bash
set -e

# Loom Agent Image Entrypoint
# Handles initialization and optionally starts Warp

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[loom]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[loom]${NC} $1"
}

log_error() {
    echo -e "${RED}[loom]${NC} $1"
}

log_debug() {
    if [ "$LOOM_DEBUG" = "true" ]; then
        echo -e "${BLUE}[loom:debug]${NC} $1"
    fi
}

# Generate agent ID if not provided
if [ -z "$AGENT_ID" ]; then
    export AGENT_ID="agent-$(hostname | cut -c1-8)-$(date +%s | tail -c 6)"
fi

# Mask credentials in URL for logging
mask_url() {
    echo "$1" | sed -E 's|://[^:]+:[^@]+@|://***:***@|g'
}

# Log startup info
log_info "Loom Agent Container v1.0"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "  Agent:        ${LOOM_AGENT:-unknown}"
log_info "  Runtime:      ${LOOM_RUNTIME:-unknown}"
log_info "  Variant:      ${LOOM_VARIANT:-unknown}"
log_info "  Agent ID:     $AGENT_ID"
log_info "  Project:      $PROJECT_ID"
log_info "  NATS URL:     $(mask_url "$NATS_URL")"
log_info "  Capabilities: $AGENT_CAPABILITIES"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Validate required environment variables based on agent type
case "$LOOM_AGENT" in
    claude)
        if [ -z "$ANTHROPIC_API_KEY" ]; then
            log_error "ANTHROPIC_API_KEY is required for Claude Code agent"
            log_error "Set it via: -e ANTHROPIC_API_KEY=your-key"
            exit 1
        fi
        log_info "Claude API key: ****${ANTHROPIC_API_KEY: -4}"
        ;;
    copilot)
        log_warn "Copilot CLI agent is not yet implemented"
        ;;
    aider)
        log_warn "Aider agent is not yet implemented"
        ;;
esac

# Check NATS URL
if [ -z "$NATS_URL" ]; then
    log_warn "NATS_URL not set - Warp will not be able to connect to Loom infrastructure"
fi

# Auto-start Warp if requested
if [ "$LOOM_AUTO_START_WARP" = "true" ] || [ "$LOOM_AUTO_START_WARP" = "1" ]; then
    log_info "Auto-starting Warp MCP server..."
    warp &
    WARP_PID=$!
    sleep 2

    if kill -0 $WARP_PID 2>/dev/null; then
        log_info "Warp started (PID: $WARP_PID)"
    else
        log_error "Warp failed to start"
        exit 1
    fi
fi

# If CLAUDE_TASK is set, run Claude with that task
if [ -n "$CLAUDE_TASK" ] && [ "$LOOM_AGENT" = "claude" ]; then
    log_info "Running Claude task: $CLAUDE_TASK"
    exec claude "$CLAUDE_TASK"
fi

# Execute the command passed to the container
exec "$@"
