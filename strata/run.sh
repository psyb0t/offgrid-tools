#!/bin/bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
readonly IMAGE=qwen-strata-local:fb58e0d
readonly SETUP_RESERVE_KIB=33554432
readonly CATALOG="$script_dir/models.json"
readonly SETTINGS="$script_dir/settings.json"
usage() {
	printf '%s\n' 'Usage: ./strata/run.sh [options]' \
		'  --list-models                  Show supported presets without downloading' \
		'  --model ID                     Select a preset, saved after successful setup' \
		'  --context N                    Context tokens, 512..262144' \
		'  --memory-gib N                 Container RAM cap' \
		'  --resident-gib N               Expert RAM budget, at least 8 GiB below the cap' \
		'  --cpus N                       CPU limit, 1..256' \
		'  --vram-reserve-mib N           VRAM kept free, 256..32768 MiB' \
		'  --port N                       Localhost port, 1024..65535' \
		'  --gguf-dir PATH                Reuse matching shards in a read-only directory' \
		'  --setup-only                   Prepare without starting' \
		'  --offline                      Refuse setup, builds and downloads'
}
mode=run
list=false
model="${STRATA_MODEL:-}"
external_dir="${STRATA_GGUF_DIR:-}"
declare -A overrides=()
while (($#)); do
	case "$1" in
	--help | -h)
		usage
		exit 0
		;;
	--list-models)
		list=true
		shift
		;;
	--setup-only | --offline)
		[[ "$mode" == run ]] || {
			usage >&2
			exit 2
		}
		mode="$1"
		shift
		;;
	--model | --context | --memory-gib | --resident-gib | --cpus | --cpu-threads | --vram-reserve-mib | --port | --gguf-dir)
		[[ $# -ge 2 && -n "$2" && "$2" != --* ]] || {
			usage >&2
			exit 2
		}
		key="$1"
		value="$2"
		shift 2
		case "$key" in
		--model) model="$value" ;;
		--gguf-dir) external_dir="$value" ;;
		--context) overrides[context]="$value" ;;
		--memory-gib) overrides[memory_gib]="$value" ;;
		--resident-gib) overrides[resident_gib]="$value" ;;
		--cpus | --cpu-threads) overrides[cpu_threads]="$value" ;;
		--vram-reserve-mib) overrides[vram_reserve_mib]="$value" ;;
		--port) overrides[port]="$value" ;;
		esac
		;;
	*)
		usage >&2
		exit 2
		;;
	esac
done
command -v jq >/dev/null || {
	printf 'Missing command: jq\n' >&2
	exit 1
}
list_models() {
	jq -r 'to_entries[] | [.key,.value.name,((.value.files|map(.bytes)|add)/1e8|round/10|tostring)+" GB",(.value.min_ram_gib|tostring)+" GiB minimum RAM"]|@tsv' "$CATALOG"
}
if "$list"; then
	list_models
	exit 0
fi
saved='{}'
if [[ -f "$SETTINGS" ]]; then
	saved="$(jq -ce 'select(type=="object" and (.model|type=="string"))' "$SETTINGS")" || {
		printf 'Invalid strata/settings.json\n' >&2
		exit 2
	}
fi
if [[ -z "$model" ]]; then
	model="$(jq -r '.model // empty' <<<"$saved")"
	if [[ -z "$model" && -f "$script_dir/setup.py" ]]; then model=orca-q4-k-s; fi
	if [[ -z "$model" ]]; then
		list_models >&2
		[[ -t 0 ]] || {
			printf 'Select a preset with --model ID on the first run.\n' >&2
			exit 2
		}
		read -r -p 'Model ID: ' model
	fi
fi
profile="$(jq -ce --arg model "$model" '(.[$model] // empty) | .port //= 8080' "$CATALOG")" || {
	printf 'Unknown Strata model preset.\n' >&2
	exit 2
}
if [[ "$(jq -r '.model // empty' <<<"$saved")" == "$model" ]]; then
	profile="$(jq -cn --argjson preset "$profile" --argjson saved "$saved" '$preset * ($saved|{context,memory_gib,resident_gib,cpu_threads,vram_reserve_mib,port}|with_entries(select(.value!=null)))')"
	if [[ -z "$external_dir" ]]; then external_dir="$(jq -r '.gguf_dir // empty' <<<"$saved")"; fi
fi
for field in context memory_gib resident_gib cpu_threads vram_reserve_mib port; do
	case "$field" in
	context) env_value="${STRATA_CONTEXT:-}" ;;
	memory_gib) env_value="${STRATA_MEMORY_GIB:-}" ;;
	resident_gib) env_value="${STRATA_RESIDENT_GIB:-}" ;;
	cpu_threads) env_value="${STRATA_CPUS:-}" ;;
	vram_reserve_mib) env_value="${STRATA_VRAM_RESERVE_MIB:-}" ;;
	port) env_value="${STRATA_PORT:-}" ;;
	esac
	value="${overrides[$field]:-$env_value}"
	if [[ -n "$value" ]]; then
		[[ "$value" =~ ^[0-9]{1,6}$ ]] || {
			printf 'Invalid numeric option: %s\n' "$field" >&2
			exit 2
		}
		profile="$(jq -c --arg field "$field" --argjson value "$((10#$value))" '.[$field]=$value' <<<"$profile")"
	fi
done
jq -e '
    (.context|type=="number" and floor==. and .>=512 and .<=262144) and
    (.memory_gib|type=="number" and floor==. and .>=12 and .<=1024) and
    (.resident_gib|type=="number" and floor==. and .>=1) and
    (.resident_gib<=.memory_gib-8) and
    (.cpu_threads|type=="number" and floor==. and .>=1 and .<=256) and
    (.vram_reserve_mib|type=="number" and floor==. and .>=256 and .<=32768) and
    (.port|type=="number" and floor==. and .>=1024 and .<=65535)
' <<<"$profile" >/dev/null || {
	printf 'Invalid settings or resident budget too close to RAM cap.\n' >&2
	exit 2
}
for dependency in docker flock; do
	command -v "$dependency" >/dev/null || {
		printf 'Missing command: %s\n' "$dependency" >&2
		exit 1
	}
done
log() {
	jq -nc --arg time "$(date -u +%FT%TZ)" --arg level "$1" --arg msg "$2" \
		--arg line "${BASH_LINENO[0]}" '{time:$time,level:$level,file:"strata/run.sh",line:($line|tonumber),func:"main",msg:$msg}' >&2
}
trap 'log ERROR "Strata launcher failed; see the log above"' ERR
log_file="$(mktemp /tmp/offgrid-strata-run.XXXXXX.log)"
exec > >(tee -a "$log_file") 2>&1
docker info >/dev/null || {
	log ERROR 'Docker daemon is unavailable'
	exit 1
}
exec 9>"$script_dir/.setup.lock"
flock 9
export STRATA_RUNTIME_DIR="$script_dir/runtime"
if [[ -f "$script_dir/setup.py" ]]; then export STRATA_RUNTIME_DIR="$script_dir"; fi
STRATA_UID="$(id -u)"
STRATA_GID="$(id -g)"
STRATA_MEMORY_GIB="$(jq -r .memory_gib <<<"$profile")"
STRATA_CPUS="$(jq -r .cpu_threads <<<"$profile")"
STRATA_PORT="$(jq -r .port <<<"$profile")"
STRATA_PACK_NAME="$(jq -r .pack <<<"$profile")"
STRATA_MIN_VRAM_MIB="$(jq -r .min_vram_mib <<<"$profile")"
STRATA_MODEL_ID="$model"
profile_digest="$(jq -Sc . <<<"$profile" | sha256sum)"
STRATA_CONFIG="data/offgrid/$model-${profile_digest:0:16}.json"
export STRATA_UID STRATA_GID STRATA_MEMORY_GIB STRATA_CPUS STRATA_PORT STRATA_PACK_NAME STRATA_MIN_VRAM_MIB STRATA_MODEL_ID STRATA_CONFIG
weights="$script_dir/../models/gguf/$(jq -r .subdir <<<"$profile")"
weights_mode=rw
if [[ -n "$external_dir" ]]; then
	[[ "$external_dir" != *:* && "$external_dir" != *$'\n'* && "$external_dir" != *$'\r'* ]] || {
		log ERROR 'GGUF path contains unsupported mount characters'
		exit 2
	}
	[[ -d "$external_dir" ]] || {
		log ERROR 'GGUF directory does not exist'
		exit 2
	}
	weights="$(cd -- "$external_dir" && pwd -P)"
	external_dir="$weights"
	weights_mode=ro
fi
export STRATA_GGUF_DIR="$weights"
manifest="$(jq -r '. as $p | .files[] | [.sha256,(.bytes|tostring),(.path|split("/")|last),("https://huggingface.co/"+$p.repo+"/resolve/"+$p.revision+"/"+.path)]|@tsv' <<<"$profile")"
remaining_bytes=0
while read -r hash bytes filename url; do
	[[ "$hash" =~ ^[[:xdigit:]]{64}$ && "$filename" != */* && "$bytes" =~ ^[0-9]+$ && "$url" == https://huggingface.co/* ]]
	if [[ ! -s "$weights/$filename" ]]; then
		[[ "$weights_mode" != ro ]] || {
			log ERROR 'Supplied GGUF directory is missing a selected model shard'
			exit 1
		}
		have=0
		if [[ -f "$weights/$filename.part" ]]; then have="$(stat -c %s "$weights/$filename.part")"; fi
		if ((have < bytes)); then remaining_bytes=$((remaining_bytes + bytes - have)); fi
	fi
	if [[ "$weights_mode" == ro ]]; then
		log INFO 'Verifying an external GGUF shard; large files can take minutes'
		actual="$(sha256sum "$weights/$filename")"
		[[ "${actual%% *}" == "$hash" ]] || {
			log ERROR 'Supplied GGUF shard does not match the selected preset SHA256'
			exit 1
		}
	fi
done <<<"$manifest"
ready() {
	local file
	for file in engine/strata .venv/bin/python "data/packs/$STRATA_PACK_NAME/native_experts.txt" \
		"data/packs/$STRATA_PACK_NAME/index.txt" "data/packs/$STRATA_PACK_NAME/dense.bin" \
		"data/packs/$STRATA_PACK_NAME/tokenizer/vocab.json" data/mtp/rt/experts.bin \
		data/mtp/rt/dense.bin data/mtp/rt/dense.txt data/mtp/rt/draft_vocab.bin; do
		[[ -s "$STRATA_RUNTIME_DIR/$file" ]] || return 1
	done
	[[ -x "$STRATA_RUNTIME_DIR/engine/strata" && -x "$STRATA_RUNTIME_DIR/.venv/bin/python" && "$remaining_bytes" == 0 ]]
}
if [[ "$mode" == --offline ]]; then
	ready || {
		log ERROR 'Selected model is not installed; offline setup is unavailable'
		exit 1
	}
	docker image inspect "$IMAGE" >/dev/null || {
		log ERROR 'Load the saved Strata Docker image first'
		exit 1
	}
fi
ram_kib="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
((STRATA_MEMORY_GIB * 1048576 <= ram_kib - 8388608)) || {
	log ERROR 'RAM cap must leave at least 8 GiB for the host'
	exit 1
}
if ! ready; then
	min_ram="$(jq -r .min_ram_gib <<<"$profile")"
	((ram_kib >= min_ram * 1048576)) || {
		log ERROR 'This preset exceeds available system RAM; select a smaller quantization'
		exit 1
	}
	free_kib="$(df -Pk "$script_dir" | awk 'END {print $4}')"
	required_kib=$(((remaining_bytes + 1023) / 1024 + SETUP_RESERVE_KIB))
	((free_kib >= required_kib)) || {
		log ERROR 'Not enough free space for remaining weights plus 32 GiB setup reserve'
		exit 1
	}
	[[ -z "${HF_TOKEN:-}" || "$HF_TOKEN" =~ ^[[:alnum:]_.~+/=-]{1,8192}$ ]] || {
		log ERROR 'Malformed HF_TOKEN'
		exit 1
	}
	log WARN 'Selected model setup may download many gigabytes. Completed files are reused.'
fi
mkdir -p "$STRATA_RUNTIME_DIR/data/offgrid"
manifest_path="$STRATA_RUNTIME_DIR/data/offgrid/$model.tsv"
printf '%s\n' "$manifest" >"$manifest_path"
first="$(jq -r '.files[0].path|split("/")|last' <<<"$profile")"
ple="$(jq -r '.files[.ple].path|split("/")|last' <<<"$profile")"
jq --arg pack "$STRATA_PACK_NAME" --arg first "$first" --arg ple "$ple" --arg model "$model" \
	--argjson p "$profile" '
    def setarg($k;$v): index($k) as $i | .[$i+1]=$v;
    .args |= (setarg("--pack";"/data/bw/qwen-strata/data/packs/"+$pack) |
        setarg("--native";"/selected-model/"+$first) |
        setarg("--ple-gguf";"/selected-model/"+$ple) |
        setarg("--max-context";($p.context|tostring)) |
        setarg("--kv-resident";([$p.context,32768]|min|tostring)) |
        setarg("--resident-budget-gib";($p.resident_gib|tostring)) |
        setarg("--vram-reserve-mib";($p.vram_reserve_mib|tostring))) |
    (if $pack!="orca-q4_k_s" then .args |= setarg("--expert-profile";"/data/bw/qwen-strata/data/packs/"+$pack+"/expert-profile.bin") else . end) |
    .tokenizer="/data/bw/qwen-strata/data/packs/"+$pack+"/tokenizer" | .model_name=$model
' "$script_dir/config.json" >"$STRATA_RUNTIME_DIR/$STRATA_CONFIG.tmp"
mv "$STRATA_RUNTIME_DIR/$STRATA_CONFIG.tmp" "$STRATA_RUNTIME_DIR/$STRATA_CONFIG"
# Missing local image tags are expected on a fresh clone.
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
	docker build --pull=false -f "$script_dir/Dockerfile.local" -t "$IMAGE" "$script_dir" || {
		log ERROR 'Strata environment build failed'
		exit 1
	}
fi
if ! ready; then
	mkdir -p "$weights"
	docker run --rm --init --gpus all --user "$STRATA_UID:$STRATA_GID" \
		--read-only --cap-drop ALL --security-opt no-new-privileges \
		--memory 16g --memory-swap 16g --cpus 2 --pids-limit 512 \
		--tmpfs /tmp:rw,nosuid,size=2g --env HF_TOKEN \
		--env STRATA_MODEL_ID --env STRATA_PACK_NAME --env STRATA_MIN_VRAM_MIB \
		--env XDG_CONFIG_HOME=/data/bw/qwen-strata/.config \
		-v "$script_dir:/support:ro" -v "$STRATA_RUNTIME_DIR:/data/bw/qwen-strata" \
		-v "$weights:/selected-model:$weights_mode" \
		--workdir /data/bw/qwen-strata --entrypoint bash "$IMAGE" /support/setup-container.sh || {
		log ERROR 'Selected model setup failed; service not started'
		exit 1
	}
	remaining_bytes=0
	while read -r hash bytes filename url; do
		[[ -s "$weights/$filename" ]] || {
			log ERROR 'Setup did not produce all selected model shards'
			exit 1
		}
	done <<<"$manifest"
	ready || {
		log ERROR 'Selected model setup is incomplete'
		exit 1
	}
fi
jq -n --arg model "$model" --arg gguf "$external_dir" --argjson p "$profile" \
	'$p|{context,memory_gib,resident_gib,cpu_threads,vram_reserve_mib,port}+{model:$model,gguf_dir:$gguf}' >"$SETTINGS.tmp"
mv "$SETTINGS.tmp" "$SETTINGS"
if [[ "$mode" == --setup-only ]]; then
	log INFO 'Selected model prepared; service not started'
	exit 0
fi
log INFO 'Starting only Strata with the selected preset'
docker compose --project-directory "$script_dir/.." -f "$script_dir/../docker-compose.yml" \
	up -d --no-build --no-deps --pull never strata || {
	log ERROR 'Strata service startup failed'
	exit 1
}
