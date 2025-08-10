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
    echo "--rm -it -v \"$(pwd)/data\":/data -v \"$(pwd)/system-prompts\":/system-prompts"
}

# Get base llama.cpp parameters with standard defaults
get_base_llama_params() {
    local model_path="$1"

    # Core model and mode settings
    local params="-m \"$model_path\""
    params="$params -cnv"                      # Enable conversation mode

    # Context and generation settings
    params="$params --ctx-size 8192"           # Context window size
    params="$params -n -1"                     # Generate unlimited tokens (until stop)
    params="$params --chat-template chatml"    # Chat template format

    # Sampling parameters for quality output
    params="$params --temp 0.8"                # Temperature (0.0-2.0, default 0.8)
    params="$params --top-p 0.9"               # Top-p nucleus sampling (0.0-1.0, default 0.9)
    params="$params --top-k 40"                # Top-k sampling (default 40)
    params="$params --repeat-penalty 1.1"     # Repetition penalty (default 1.1)
    params="$params --repeat-last-n 64"       # Last N tokens to penalize (default 64)

    # Performance and threading
    params="$params --threads -1"              # Auto-detect CPU threads
    params="$params -b 512"                   # Batch size for prompt processing

    # Additional settings
    params="$params --seed -1"                 # Random seed (-1 = random)
    params="$params --mirostat 0"              # Mirostat sampling (0=disabled, 1=v1, 2=v2)

    # Output formatting
    params="$params --color"                   # Enable colored output

    echo "$params"
}

# Get custom llama.cpp parameters (override defaults)
get_custom_llama_params() {
    local model_path="$1"
    shift  # Remove model_path from arguments

    # Start with base parameters
    local params=$(get_base_llama_params "$model_path")

    # Process arguments and resolve system prompt paths
    local processed_args=""
    local prev_arg=""

    for arg in "$@"; do
        if [[ "$prev_arg" == "--system-prompt-file" ]]; then
            # Resolve the system prompt file path
            resolved_path=$(resolve_system_prompt_path "$arg")
            processed_args="$processed_args $resolved_path"
        else
            processed_args="$processed_args $arg"
        fi
        prev_arg="$arg"
    done

    # Add processed arguments
    if [ ${#processed_args} -gt 0 ]; then
        params="$params$processed_args"
    fi

    echo "$params"
}

# Display available parameter options
show_parameter_help() {
    echo "Available llama.cpp parameters (add to command line):"
    echo ""
    echo "Sampling Parameters:"
    echo "  --temp 0.8              Temperature (0.0-2.0, lower=deterministic)"
    echo "  --top-p 0.9             Top-p nucleus sampling (0.0-1.0)"
    echo "  --top-k 40              Top-k sampling (number of tokens)"
    echo "  --repeat-penalty 1.1    Repetition penalty (>1.0 reduces repetition)"
    echo "  --repeat-last-n 64      Last N tokens to consider for penalty"
    echo ""
    echo "Generation Settings:"
    echo "  --ctx-size 8192         Context window size"
    echo "  -n 512                  Number of tokens to generate (-1 = unlimited)"
    echo "  --seed 42               Random seed (-1 = random)"
    echo "  --chat-template chatml  Chat template format"
    echo ""
    echo "System Messages:"
    echo "  --system \"message\"       Set system prompt directly"
    echo "  --system-prompt-file f  Load system prompt from file"
    echo "  (Default uses generic.txt if it exists)"
    echo "  Available: generic.txt, coding.txt, creative.txt,"
    echo "             technical.txt, anarchist.txt"
    echo ""
    echo "Performance:"
    echo "  --threads 8             Number of CPU threads (-1 = auto)"
    echo "  -b 512                  Batch size for processing"
    echo "  --ngl 20                Number of GPU layers (GPU mode only)"
    echo ""
    echo "Advanced Sampling:"
    echo "  --mirostat 2            Mirostat sampling (0=off, 1=v1, 2=v2)"
    echo ""
    echo "Output:"
    echo "  --color                 Enable colored output"
    echo ""
    echo "Examples:"
    echo "  ./run-cpu.sh model.gguf --temp 0.7 --top-p 0.95 -n 256"
    echo "  ./run-gpu.sh model.gguf --repeat-penalty 1.5 --repeat-last-n 64"
    echo "  ./run-gpu.sh model.gguf --ngl 20 --temp 0.8"
    echo "  ./run-cpu.sh model.gguf --system \"You are a helpful coding assistant\""
    echo "  ./run-gpu.sh model.gguf --system-prompt-file coding.txt"
    echo "  ./run-cpu.sh model.gguf --system-prompt-file anarchist.txt --temp 0.9"
}

# Add system message parameters if available
add_system_message_params() {
    local params="$1"

    # Check if default generic.txt exists and no custom system message is set
    if [ -f "system-prompts/generic.txt" ] && [[ "$params" != *"--system"* ]]; then
        params="$params --system-prompt-file /system-prompts/generic.txt"
    fi

    echo "$params"
}

# Resolve system prompt file path (allow short names)
resolve_system_prompt_path() {
    local prompt_arg="$1"

    # If it's a --system-prompt-file argument, check if it's just a filename
    if [[ "$prompt_arg" == "--system-prompt-file" ]]; then
        return 0  # Let the next argument be processed
    fi

    # If it looks like just a filename (no path separators), prepend system-prompts path
    if [[ "$prompt_arg" != *"/"* ]] && [[ "$prompt_arg" == *.txt ]]; then
        echo "/system-prompts/$prompt_arg"
    else
        echo "$prompt_arg"
    fi
}

# Main runner function - handles both CPU and GPU modes
run_llama_model() {
    local engine_type="$1"
    shift

    # Check for help flag
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: $(basename "$0") <model_name.gguf> [additional_params...]"
        echo ""
        validate_model "$(basename "$0")"  # This will show usage and available models
        echo ""
        show_parameter_help
        exit 0
    fi

    # Validate model and get model name
    MODEL_NAME=$(validate_model "$(basename "$0")" "$@")

    # Get paths and parameters (including any additional arguments)
    MODEL_PATH=$(get_model_path "$MODEL_NAME")
    DOCKER_PARAMS=$(get_common_docker_params)

    # Get parameters with any additional arguments after model name
    # Skip the model name (first argument) and pass the rest
    shift  # Remove model name
    if [ $# -gt 0 ]; then
        LLAMA_PARAMS=$(get_custom_llama_params "$MODEL_PATH" "$@")
    else
        LLAMA_PARAMS=$(get_base_llama_params "$MODEL_PATH")
    fi

    # Add system message if available (and not overridden by user)
    LLAMA_PARAMS=$(add_system_message_params "$LLAMA_PARAMS")

    # Set Docker image and additional parameters based on engine type
    if [[ "$engine_type" == "gpu" ]]; then
        echo "Running llama.cpp with GPU acceleration and model: $MODEL_NAME"
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:light-cuda"
        DOCKER_GPU="--gpus all"
        # Add default GPU layers if not already specified by user
        if [[ "$LLAMA_PARAMS" != *"--ngl"* ]]; then
            LLAMA_PARAMS="$LLAMA_PARAMS --ngl 20"
        fi
    else
        echo "Running llama.cpp with model: $MODEL_NAME"
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:light"
        DOCKER_GPU=""
    fi

    # Run Docker container
    eval "docker run $DOCKER_GPU $DOCKER_PARAMS $DOCKER_IMAGE $LLAMA_PARAMS"
}

# Server runner function - handles both CPU and GPU server modes
run_llama_server() {
    local engine_type="$1"
    shift

    # Check for help flag or no arguments
    if [[ "$1" == "--help" || "$1" == "-h" || $# -eq 0 ]]; then
        if [[ "$engine_type" == "gpu" ]]; then
            echo "Usage: $(basename "$0") <model_name.gguf> [--ngl layers]"
            echo ""
            echo "  --ngl layers: Number of layers to offload to GPU (default: 999 for all layers)"
            echo "                Use 0 for CPU-only processing"
        else
            echo "Usage: $(basename "$0") <model_name.gguf>"
        fi
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
    
    # Parse --ngl parameter if provided (GPU mode only)
    GPU_LAYERS=""
    if [[ "$engine_type" == "gpu" && $# -gt 1 ]]; then
        if [[ "$2" == "--ngl" && $# -gt 2 ]]; then
            GPU_LAYERS="$3"
            # Validate it's a number
            if ! [[ "$GPU_LAYERS" =~ ^[0-9]+$ ]]; then
                echo "Error: --ngl parameter must be a number"
                exit 1
            fi
        else
            echo "Error: Invalid parameter. Use --ngl <number> to specify GPU layers"
            exit 1
        fi
    fi

    # Get paths and basic parameters only
    MODEL_PATH=$(get_model_path "$MODEL_NAME")
    DOCKER_PARAMS=$(get_server_docker_params)
    SERVER_PARAMS=$(get_base_server_params "$MODEL_PATH")

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
        echo "Web UI will be available at: http://localhost:9000"
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:server-cuda"
        DOCKER_GPU="--gpus all"
    else
        echo "Starting llama.cpp server with model: $MODEL_NAME"
        echo "Web UI will be available at: http://localhost:9000"
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:server"
        DOCKER_GPU=""
    fi

    echo "Configure temperature, system prompts, and other settings in the web UI."
    echo ""

    # Run Docker container
    eval "docker run $DOCKER_GPU $DOCKER_PARAMS $DOCKER_IMAGE $SERVER_PARAMS"
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
