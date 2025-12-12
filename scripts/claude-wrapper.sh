#!/bin/bash
# Claude Code wrapper script
# Provides convenient shortcuts for common operations

set -e

usage() {
    cat << EOF
Claude Code Wrapper for Loom Agent Images

Usage: claude-wrapper.sh <command> [options]

Commands:
    task <description>     Run Claude with a task description
    chat                   Start interactive chat mode
    review <path>          Code review a file or directory
    fix <issue>            Fix an issue in the current directory
    test                   Run tests and fix failures
    help                   Show this help message

Environment Variables:
    ANTHROPIC_API_KEY      Required - Your Anthropic API key
    CLAUDE_MODEL           Optional - Model to use (default: claude-sonnet-4-20250514)
    CLAUDE_MAX_TOKENS      Optional - Max tokens (default: 8192)

Examples:
    claude-wrapper.sh task "Add input validation to the login form"
    claude-wrapper.sh review src/
    claude-wrapper.sh fix "TypeError in user service"
EOF
}

# Verify API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY is not set"
    exit 1
fi

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    task)
        if [ -z "$1" ]; then
            echo "Error: Task description required"
            echo "Usage: claude-wrapper.sh task <description>"
            exit 1
        fi
        exec claude "$@"
        ;;
    chat)
        exec claude
        ;;
    review)
        PATH_TO_REVIEW="${1:-.}"
        exec claude "Please review the code in $PATH_TO_REVIEW for potential issues, bugs, security concerns, and improvements. Provide actionable feedback."
        ;;
    fix)
        if [ -z "$1" ]; then
            echo "Error: Issue description required"
            echo "Usage: claude-wrapper.sh fix <issue>"
            exit 1
        fi
        exec claude "Please fix the following issue: $*"
        ;;
    test)
        exec claude "Run the test suite, analyze any failures, and fix them. Make sure all tests pass before finishing."
        ;;
    help|--help|-h)
        usage
        exit 0
        ;;
    *)
        echo "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
