#!/bin/bash
# Claude Code specific entrypoint wrapper
# Called after the base entrypoint

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[claude-agent]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[claude-agent]${NC} $1"
}

log_error() {
    echo -e "${RED}[claude-agent]${NC} $1"
}

# Check for Anthropic API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    log_error "ANTHROPIC_API_KEY is not set!"
    log_error "Claude Code requires an API key to function."
    log_error "Set it via: -e ANTHROPIC_API_KEY=your-key"
    exit 1
fi

log_info "Claude Code agent ready"
log_info "  Claude version: $(claude --version 2>/dev/null || echo 'unknown')"

# If a task was provided via CLAUDE_TASK, run it
if [ -n "$CLAUDE_TASK" ]; then
    log_info "Running task: $CLAUDE_TASK"
    exec claude "$CLAUDE_TASK"
fi

# Otherwise, pass through to the command
exec "$@"
