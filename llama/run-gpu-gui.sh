#!/bin/bash
set -euo pipefail

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Run llama.cpp server with GPU acceleration and web UI
# Model paths are under /app/models inside the container.
run_llama_server "gpu" "$@"
