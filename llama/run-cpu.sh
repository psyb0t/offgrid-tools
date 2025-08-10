#!/bin/bash

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Run llama.cpp with CPU-only mode
run_llama_model "cpu" "$@"