#!/bin/bash
set -euo pipefail

log() {
	printf '{"time":"%s","level":"%s","file":"llama/common.sh","line":%d,"func":"launcher","msg":"%s"}\n' \
		"$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1" "${BASH_LINENO[0]}" "$2" >&2
}

trap 'log ERROR "Launcher command failed"' ERR

run_llama_server() {
	local engine_type="$1"
	shift
	local script_dir image server_port=9000 has_port=false index
	local -a docker_options=() arguments=("$@")
	script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

	case "$engine_type" in
	gpu)
		image="ghcr.io/ggml-org/llama.cpp:server-cuda"
		docker_options=(--gpus all)
		;;
	cpu) image="ghcr.io/ggml-org/llama.cpp:server" ;;
	*)
		log ERROR "Expected CPU or GPU launch mode"
		return 2
		;;
	esac

	for ((index = 0; index < ${#arguments[@]}; index++)); do
		case "${arguments[index]}" in
		--port)
			if ((index + 1 >= ${#arguments[@]})); then
				log ERROR "Missing port value"
				return 2
			fi
			server_port="${arguments[index + 1]}"
			has_port=true
			;;
		--port=*)
			server_port="${arguments[index]#--port=}"
			has_port=true
			;;
		esac
	done
	if [[ ! "$server_port" =~ ^[0-9]{1,5}$ ]] || ((10#$server_port < 1 || 10#$server_port > 65535)); then
		log ERROR "Port must be between 1 and 65535"
		return 2
	fi
	if [[ "$has_port" == false ]]; then
		arguments=(--port "$server_port" "${arguments[@]}")
	fi

	docker run -it --rm --pull never "${docker_options[@]}" \
		--cap-drop ALL --security-opt no-new-privileges \
		-v "$script_dir/../models/gguf:/app/models:ro" \
		-v "$script_dir/system-prompts:/app/system-prompts:ro" \
		-p "127.0.0.1:$server_port:$server_port" \
		"$image" --host 0.0.0.0 "${arguments[@]}" || {
		local status=$?
		log ERROR "llama.cpp container failed"
		return "$status"
	}
}
