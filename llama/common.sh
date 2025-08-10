#!/bin/bash

# Common functions for llama.cpp GUI server runners

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

# Get server-specific Docker parameters (includes port mapping)
get_server_docker_params() {
    echo "-it --rm -v \"$(pwd)/data\":/data -p 9000:9000"
}

# Get base server parameters
get_base_server_params() {
    local model_path="$1"
    
    # Minimal server parameters - everything else configurable in UI
    local params="-m \"$model_path\""
    params="$params --host 0.0.0.0"               # Listen on all interfaces
    params="$params --port 9000"                  # Server port
    
    echo "$params"
}

# Server runner function - handles both CPU and GPU server modes
run_llama_server() {
    local engine_type="$1"
    shift
    
    # Check for help flag or no arguments
    if [[ "$1" == "--help" || "$1" == "-h" || $# -eq 0 ]]; then
        if [[ "$engine_type" == "gpu" ]]; then
            echo "Usage: $(basename "$0") <model_name.gguf> [--ngl layers] [--mmproj mmproj_file.gguf]"
            echo ""
            echo "  --ngl layers: Number of layers to offload to GPU (default: 999 for all layers)"
            echo "                Use 0 for CPU-only processing"
        else
            echo "Usage: $(basename "$0") <model_name.gguf> [--mmproj mmproj_file.gguf]"
        fi
        echo ""
        echo "  --mmproj file: Multimodal projector file for vision/image capabilities"
        echo ""
        echo "Starts llama.cpp server with web UI at http://localhost:9000"
        echo "All parameters (temperature, system prompts, etc.) can be configured in the web UI."
        echo ""
        if [ $# -eq 0 ]; then
            echo "Available models:"
            list_available_models
        fi
        exit 0
    fi

    # Validate model and get model name
    MODEL_NAME=$(validate_model "$(basename "$0")" "$1" "dummy")
    
    # Parse optional parameters
    GPU_LAYERS=""
    MMPROJ_FILE=""
    
    # Process arguments after model name
    shift  # Remove model name
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ngl)
                if [[ "$engine_type" != "gpu" ]]; then
                    echo "Error: --ngl parameter only available for GPU mode"
                    exit 1
                fi
                if [[ $# -lt 2 ]]; then
                    echo "Error: --ngl requires a number"
                    exit 1
                fi
                GPU_LAYERS="$2"
                if ! [[ "$GPU_LAYERS" =~ ^[0-9]+$ ]]; then
                    echo "Error: --ngl parameter must be a number"
                    exit 1
                fi
                shift 2
                ;;
            --mmproj)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --mmproj requires a filename"
                    exit 1
                fi
                MMPROJ_FILE="$2"
                if [[ ! -f "data/$MMPROJ_FILE" ]]; then
                    echo "Error: mmproj file 'data/$MMPROJ_FILE' not found"
                    exit 1
                fi
                shift 2
                ;;
            *)
                echo "Error: Unknown parameter '$1'"
                echo "Use --help to see available parameters"
                exit 1
                ;;
        esac
    done

    # Get paths and basic parameters only
    MODEL_PATH=$(get_model_path "$MODEL_NAME")
    DOCKER_PARAMS=$(get_server_docker_params)
    SERVER_PARAMS=$(get_base_server_params "$MODEL_PATH")

    # Add mmproj parameter if specified
    if [[ -n "$MMPROJ_FILE" ]]; then
        MMPROJ_PATH=$(get_model_path "$MMPROJ_FILE")
        SERVER_PARAMS="$SERVER_PARAMS --mmproj \"$MMPROJ_PATH\""
    fi
    
    # Set Docker image based on engine type
    if [[ "$engine_type" == "gpu" ]]; then
        echo "Starting llama.cpp server with GPU acceleration and model: $MODEL_NAME"
        if [[ -n "$GPU_LAYERS" ]]; then
            echo "GPU layers: $GPU_LAYERS"
            SERVER_PARAMS="$SERVER_PARAMS -ngl $GPU_LAYERS"
        else
            echo "GPU layers: 999 (all layers)"
            SERVER_PARAMS="$SERVER_PARAMS -ngl 999"
        fi
        if [[ -n "$MMPROJ_FILE" ]]; then
            echo "Multimodal projector: $MMPROJ_FILE (vision capabilities enabled)"
        fi
        echo "Web UI will be available at: http://localhost:9000"
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:server-cuda"
        DOCKER_GPU="--gpus all"
    else
        echo "Starting llama.cpp server with model: $MODEL_NAME"
        if [[ -n "$MMPROJ_FILE" ]]; then
            echo "Multimodal projector: $MMPROJ_FILE (vision capabilities enabled)"
        fi
        echo "Web UI will be available at: http://localhost:9000"
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:server"
        DOCKER_GPU=""
    fi

    echo "Configure temperature, system prompts, and other settings in the web UI."
    echo ""
    
    # Run Docker container
    eval "docker run $DOCKER_GPU $DOCKER_PARAMS $DOCKER_IMAGE $SERVER_PARAMS"
}