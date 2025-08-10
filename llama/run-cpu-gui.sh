#!/bin/bash

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Run llama.cpp server with CPU-only mode and web UI
# Example: ./run-cpu-gui.sh -m models/gpt-oss-20b-Q4_K_M.gguf
run_llama_server "cpu" "$@"