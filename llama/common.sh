#!/bin/bash

# Common functions for llama.cpp runners

# Check if model name is provided and validate it
validate_model() {
    local script_name="$1"
    
    if [ $# -lt 2 ]; then
        echo "Usage: $script_name <model_name.gguf>"
        echo "Example: $script_name gpt-oss-20b-Q4_K_M.gguf"
        echo "Available models:"
        list_available_models
        exit 1
    fi
    
    local model_name="$2"
    
    # Check if model file exists
    if [ ! -f "data/$model_name" ]; then
        echo "Error: Model file 'data/$model_name' not found"
        echo "Available models:"
        list_available_models
        exit 1
    fi
    
    echo "$model_name"
}

# List available models in the data directory
list_available_models() {
    ls -1 data/ 2>/dev/null | grep -E '\.gguf$' || echo "  No models found in data/ directory"
}

# Get the model path for Docker container
get_model_path() {
    local model_name="$1"
    echo "/data/$model_name"
}

# Common Docker run parameters
get_common_docker_params() {
    echo "--rm -it -v \"$(pwd)/data\":/data"
}

# Get base llama.cpp parameters
get_base_llama_params() {
    local model_path="$1"
    echo "-m \"$model_path\" -cnv --ctx-size 8192"
}