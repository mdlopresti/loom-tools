#!/bin/bash
set -e

# Loom Agent Image Entrypoint
# This script handles initialization and optionally starts Warp

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[loom-agent]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[loom-agent]${NC} $1"
}

log_error() {
    echo -e "${RED}[loom-agent]${NC} $1"
}

# Generate agent ID if not provided
if [ -z "$AGENT_ID" ]; then
    export AGENT_ID="agent-$(hostname)-$(date +%s)"
fi

# Log configuration
log_info "Loom Agent Container Starting"
log_info "  Agent ID: $AGENT_ID"
log_info "  Project: $PROJECT_ID"
log_info "  NATS URL: ${NATS_URL%%@*}@***" # Hide credentials
log_info "  Capabilities: $AGENT_CAPABILITIES"

# Check for required environment variables
if [ -z "$NATS_URL" ]; then
    log_warn "NATS_URL not set - Warp will not be able to connect"
fi

# Auto-start Warp if LOOM_AUTO_START_WARP is set
if [ "$LOOM_AUTO_START_WARP" = "true" ] || [ "$LOOM_AUTO_START_WARP" = "1" ]; then
    log_info "Auto-starting Warp MCP server..."
    warp &
    WARP_PID=$!
    sleep 2

    if kill -0 $WARP_PID 2>/dev/null; then
        log_info "Warp started successfully (PID: $WARP_PID)"
    else
        log_error "Warp failed to start"
        exit 1
    fi
fi

# Execute the command passed to the container
exec "$@"
