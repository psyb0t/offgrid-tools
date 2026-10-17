#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly IMAGE='qwen-strata-local:fb58e0d'
readonly IMAGE_DIR="$SCRIPT_DIR/docker-images"
readonly ARCHIVE="$IMAGE_DIR/qwen-strata-local_fb58e0d.tar"
readonly CHECKSUM="$ARCHIVE.sha256"
readonly INSTALL_DIR="$SCRIPT_DIR/strata"

usage() {
	printf 'Usage: %s {save|build-save|load}\n' "$0"
}
if [[ $# != 1 || ! "$1" =~ ^(save|build-save|load)$ ]]; then
	usage >&2
	exit 2
fi
for dependency in docker jq sha256sum flock; do
	command -v "$dependency" >/dev/null || {
		printf 'Missing command: %s\n' "$dependency" >&2
		exit 1
	}
done
log() {
	local level="$1"
	shift
	jq -nc --arg time "$(date -u +%FT%TZ)" --arg level "$level" \
		--arg file "${BASH_SOURCE[1]##*/}" --arg line "${BASH_LINENO[0]}" \
		--arg func "${FUNCNAME[1]:-main}" --arg msg "$*" \
		'{time:$time,level:$level,file:$file,line:($line|tonumber),func:$func,msg:$msg}' >&2
}
trap 'log ERROR "Command failed at line $LINENO, exit $?"' ERR
LOG_FILE="$(mktemp /tmp/strata-image.XXXXXX.log)"
readonly LOG_FILE
exec > >(tee -a "$LOG_FILE") 2>&1
staging=''
cleanup() {
	if [[ -n "$staging" && -d "$staging" ]]; then
		rm -f -- "$staging/image.tar" "$staging/image.sha256"
		rmdir -- "$staging"
	fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$IMAGE_DIR"
exec 9>"$IMAGE_DIR/.strata-image.lock"
flock 9
[[ -z "${DEBUG:-}" ]] || log DEBUG "Operation $1, image $IMAGE"

if [[ "$1" == load ]]; then
	[[ -s "$ARCHIVE" && -s "$CHECKSUM" ]] || {
		log ERROR 'Strata archive or SHA256 sidecar missing'
		exit 1
	}
	read -r expected _ <"$CHECKSUM"
	[[ "$expected" =~ ^[[:xdigit:]]{64}$ ]] || {
		log ERROR 'Malformed SHA256 sidecar'
		exit 1
	}
	actual="$(sha256sum "$ARCHIVE")"
	[[ "${actual%% *}" == "${expected,,}" ]] || {
		log ERROR 'Strata archive SHA256 mismatch'
		exit 1
	}
	log INFO "Loading verified archive $ARCHIVE"
	docker load -i "$ARCHIVE" || {
		log ERROR 'Docker image load failed'
		exit 1
	}
	exit 0
fi
# A missing local tag is expected on a new machine; Docker inspect prints an error for it.
if [[ "$1" == build-save ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
	[[ -s "$INSTALL_DIR/Dockerfile.local" ]] || {
		log ERROR 'Local Strata Dockerfile missing; restore the Strata installation first'
		exit 1
	}
	log INFO "Building $IMAGE from the local Dockerfile"
	docker build --pull=false -f "$INSTALL_DIR/Dockerfile.local" -t "$IMAGE" "$INSTALL_DIR" || {
		log ERROR 'Strata image build failed'
		exit 1
	}
fi
staging="$(mktemp -d "$IMAGE_DIR/.strata-save.XXXXXX")"
log INFO "Saving $IMAGE"
docker save -o "$staging/image.tar" "$IMAGE" || {
	log ERROR 'Docker save failed; existing archive retained'
	exit 1
}
[[ -s "$staging/image.tar" ]] || {
	log ERROR 'Docker produced an empty archive'
	exit 1
}
digest="$(sha256sum "$staging/image.tar")"
printf '%s  %s\n' "${digest%% *}" "${ARCHIVE##*/}" >"$staging/image.sha256"
chmod 644 "$staging/image.tar" "$staging/image.sha256"
if [[ -f "$ARCHIVE" ]]; then
	log WARN 'Preserving the previous archive as .previous'
	cp -l --remove-destination -- "$ARCHIVE" "$ARCHIVE.previous"
fi
if [[ -f "$CHECKSUM" ]]; then
	cp -l --remove-destination -- "$CHECKSUM" "$CHECKSUM.previous"
fi
mv -f -- "$staging/image.tar" "$ARCHIVE"
mv -f -- "$staging/image.sha256" "$CHECKSUM"
log INFO "Saved $ARCHIVE and SHA256. Keep strata/ and models/gguf/ with the image. Log: $LOG_FILE"
