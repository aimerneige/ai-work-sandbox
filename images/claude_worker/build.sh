#!/usr/bin/env bash
# =============================================================================
# build.sh -- build the claude_worker sandbox image
#
# Usage:
#   ./build.sh              # build claude-worker:latest
#   ./build.sh --no-cache   # force rebuild without cache
#
# Override image tag via env:
#   CLAUDE_WORKER_IMAGE=foo:bar ./build.sh
# =============================================================================

set -euo pipefail

IMAGE_NAME="${CLAUDE_WORKER_IMAGE:-claude-worker:latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker buildx build --load "$@" -t "$IMAGE_NAME" "$SCRIPT_DIR"
