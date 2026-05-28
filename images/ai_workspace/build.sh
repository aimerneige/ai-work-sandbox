#!/usr/bin/env bash
# =============================================================================
# build.sh -- build the ai_workspace base image
#
# This image carries the heavy, slow-changing toolchains shared by every
# downstream AI sandbox image (apt packages, Node/Go/Python/Rust/.NET, etc.)
# but does NOT install any AI CLI npm package. Downstream images add their
# AI tooling on top of this base.
#
# Usage:
#   ./build.sh              # build docker-box/ai_workspace:latest
#   ./build.sh --no-cache   # force rebuild without cache
#
# Override image tag via env:
#   AI_WORKSPACE_IMAGE=foo:bar ./build.sh
# =============================================================================

set -euo pipefail

IMAGE_NAME="${AI_WORKSPACE_IMAGE:-docker-box/ai_workspace:latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker buildx build --load "$@" -t "$IMAGE_NAME" "$SCRIPT_DIR"
