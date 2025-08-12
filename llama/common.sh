#!/bin/bash

# Simple llama.cpp Docker runner
run_llama_server() {
    local engine_type="$1"
    shift

    if [[ "$engine_type" == "gpu" ]]; then
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:server-cuda"
        DOCKER_GPU="--gpus all"
    else
        DOCKER_IMAGE="ghcr.io/ggml-org/llama.cpp:server"
        DOCKER_GPU=""
    fi

    # Add default host, port, and browser-use compatible settings
    local args="--host 0.0.0.0 $@"
    if [[ "$args" != *"--port"* ]]; then
        args="--port 9000 $args"
    fi

    docker run -it --rm $DOCKER_GPU \
        -v "$(pwd)/models":/app/models \
        -v "$(pwd)/system-prompts":/app/system-prompts \
        -p 9000:9000 \
        $DOCKER_IMAGE $args
}
