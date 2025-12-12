#!/bin/bash
# Build script for Loom Agent Images
#
# Usage:
#   ./build.sh <agent> <runtime> <variant>    Build a specific image
#   ./build.sh --all                          Build all images
#   ./build.sh --list                         List all image combinations
#
# Examples:
#   ./build.sh claude node20 full
#   ./build.sh claude multi minimal
#   ./build.sh --all

set -e

REGISTRY="${REGISTRY:-ghcr.io/mdlopresti}"
IMAGE_NAME="${IMAGE_NAME:-loom-agent}"

# Define the matrix
AGENTS=(claude)
RUNTIMES=(node20 node22 python3.11 python3.12 multi)
VARIANTS=(minimal full)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[build]${NC} $1"
}

build_image() {
    local agent=$1
    local runtime=$2
    local variant=$3
    local tag="${agent}-${runtime}-${variant}"
    local full_tag="${REGISTRY}/${IMAGE_NAME}:${tag}"

    log "Building ${BLUE}${tag}${NC}..."

    docker build \
        --build-arg AGENT="${agent}" \
        --build-arg RUNTIME="${runtime}" \
        --build-arg VARIANT="${variant}" \
        -t "${full_tag}" \
        -t "${IMAGE_NAME}:${tag}" \
        .

    log "Built: ${full_tag}"
}

list_images() {
    echo "Available image combinations:"
    echo ""
    for agent in "${AGENTS[@]}"; do
        for runtime in "${RUNTIMES[@]}"; do
            for variant in "${VARIANTS[@]}"; do
                echo "  ${agent}-${runtime}-${variant}"
            done
        done
    done
    echo ""
    echo "Total: $((${#AGENTS[@]} * ${#RUNTIMES[@]} * ${#VARIANTS[@]})) images"
}

build_all() {
    local count=0
    local total=$((${#AGENTS[@]} * ${#RUNTIMES[@]} * ${#VARIANTS[@]}))

    log "Building all ${total} images..."
    echo ""

    for agent in "${AGENTS[@]}"; do
        for runtime in "${RUNTIMES[@]}"; do
            for variant in "${VARIANTS[@]}"; do
                count=$((count + 1))
                log "Progress: ${count}/${total}"
                build_image "${agent}" "${runtime}" "${variant}"
                echo ""
            done
        done
    done

    log "All ${total} images built successfully!"
}

# Parse arguments
case "${1:-}" in
    --all)
        build_all
        ;;
    --list)
        list_images
        ;;
    --help|-h)
        echo "Usage:"
        echo "  $0 <agent> <runtime> <variant>    Build a specific image"
        echo "  $0 --all                          Build all images"
        echo "  $0 --list                         List all image combinations"
        echo ""
        echo "Agents:   ${AGENTS[*]}"
        echo "Runtimes: ${RUNTIMES[*]}"
        echo "Variants: ${VARIANTS[*]}"
        ;;
    "")
        echo "Error: Missing arguments"
        echo "Usage: $0 <agent> <runtime> <variant>"
        echo "   or: $0 --all"
        echo "   or: $0 --list"
        exit 1
        ;;
    *)
        if [ $# -ne 3 ]; then
            echo "Error: Expected 3 arguments: <agent> <runtime> <variant>"
            exit 1
        fi
        build_image "$1" "$2" "$3"
        ;;
esac
