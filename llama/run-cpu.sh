#!/bin/bash

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Validate model and get model name
MODEL_NAME=$(validate_model "$(basename "$0")" "$@")

# Get paths and parameters
MODEL_PATH=$(get_model_path "$MODEL_NAME")
DOCKER_PARAMS=$(get_common_docker_params)
LLAMA_PARAMS=$(get_base_llama_params "$MODEL_PATH")

echo "Running llama.cpp with model: $MODEL_NAME"

# Run Docker container with CPU-only image
eval "docker run $DOCKER_PARAMS ghcr.io/ggml-org/llama.cpp:light $LLAMA_PARAMS"