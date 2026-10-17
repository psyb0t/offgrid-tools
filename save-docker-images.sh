#!/usr/bin/env bash
# Save Docker images for offline distribution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/docker-images"

case "${1:-}" in
--strata-only)
	[[ $# == 1 ]] || exit 2
	exec bash "$SCRIPT_DIR/strata-image.sh" save
	;;
--build-strata)
	[[ $# == 1 ]] || exit 2
	exec bash "$SCRIPT_DIR/strata-image.sh" build-save
	;;
'') [[ $# == 0 ]] || exit 2 ;;
*)
	printf 'Usage: %s [--strata-only|--build-strata]\n' "$0" >&2
	exit 2
	;;
esac

# Function to display image information
print_images_info() {
	local show_names=${1:-false}

	if [[ "$show_names" == "false" ]]; then
		echo "=== Saving Docker Images for Offline Use ==="
		echo "This will download and save the following images:"
	else
		echo "📋 Available images for offline use:"
	fi

	echo "  📚 Kiwix: $([ "$show_names" == "true" ] && echo "ghcr.io/kiwix/kiwix-serve:latest" || echo "server for offline content")"
	echo "  🌐 Zimit: $([ "$show_names" == "true" ] && echo "ghcr.io/openzim/zimit:latest" || echo "for web content archiving")"
	echo "  🤖 Ollama: $([ "$show_names" == "true" ] && echo "ollama/ollama:latest" || echo "for local AI models")"
	echo "  🌐 Open WebUI: $([ "$show_names" == "true" ] && echo "ghcr.io/open-webui/open-webui:main" || echo "for AI chat interface")"
	echo "  🎉 Ollama Chat Party: $([ "$show_names" == "true" ] && echo "psyb0t/ollama-chat-party:latest" || echo "for RAG-enabled chat")"
	echo "  🦙 LLaMA.cpp CPU: $([ "$show_names" == "true" ] && echo "ghcr.io/ggml-org/llama.cpp:light" || echo "for local LLM inference")"
	echo "  🦙 LLaMA.cpp GPU: $([ "$show_names" == "true" ] && echo "ghcr.io/ggml-org/llama.cpp:light-cuda" || echo "for GPU-accelerated LLM inference")"
	echo "  🖥️  LLaMA.cpp Server CPU: $([ "$show_names" == "true" ] && echo "ghcr.io/ggml-org/llama.cpp:server" || echo "for local LLM server with web UI")"
	echo "  🖥️  LLaMA.cpp Server GPU: $([ "$show_names" == "true" ] && echo "ghcr.io/ggml-org/llama.cpp:server-cuda" || echo "for GPU LLM server with web UI")"
	echo "  💬 TheLounge: $([ "$show_names" == "true" ] && echo "thelounge/thelounge:latest" || echo "for web-based IRC client")"
	echo "  🌐 InspIRCd: $([ "$show_names" == "true" ] && echo "inspircd/inspircd-docker:latest" || echo "for IRC server hosting")"
	echo "  📻 Icecast: $([ "$show_names" == "true" ] && echo "libretime/icecast:latest" || echo "for audio streaming")"
	echo "  📁 Nginx: $([ "$show_names" == "true" ] && echo "nginx:alpine" || echo "web server")"
	echo "  🐍 Python: $([ "$show_names" == "true" ] && echo "python:3.12" || echo "runtime")"
	echo "  🐹 Go: $([ "$show_names" == "true" ] && echo "golang:1.24" || echo "development environment")"
	echo "  🖥️  Base: $([ "$show_names" == "true" ] && echo "ubuntu:22.04" || echo "Ubuntu OS for containers")"
}

print_images_info
echo ""

# Create images directory if it doesn't exist
mkdir -p "$IMAGES_DIR"

# List of images to save
IMAGES=(
	# Offline content server
	"ghcr.io/kiwix/kiwix-serve:latest"
	"ghcr.io/openzim/zimit:latest" # Web content archiving tool

	# AI/LLM server and UI
	"ollama/ollama:latest"               # Local AI model server
	"ghcr.io/open-webui/open-webui:main" # Web UI for Ollama
	"psyb0t/ollama-chat-party:latest"    # RAG-enabled chat interface

	# LLaMA.cpp runtime containers
	"ghcr.io/ggml-org/llama.cpp:light"       # CPU-only llama.cpp runtime
	"ghcr.io/ggml-org/llama.cpp:light-cuda"  # GPU-enabled llama.cpp runtime
	"ghcr.io/ggml-org/llama.cpp:server"      # CPU-only llama.cpp server with web UI
	"ghcr.io/ggml-org/llama.cpp:server-cuda" # GPU-enabled llama.cpp server with web UI

	# IRC chat network
	"thelounge/thelounge:latest"      # Web-based IRC client
	"inspircd/inspircd-docker:latest" # IRC server

	# Audio streaming
	"libretime/icecast:latest" # Audio streaming server

	# Web server
	"nginx:alpine" # Web server (used for file server)

	# Programming language runtimes (full versions)
	"python:3.12" # Latest stable Python (full)
	"golang:1.24" # Latest stable Go (full)

	# Base operating system for development
	"ubuntu:22.04" # LTS Ubuntu for general development
)

# Pull and save each image
for image in "${IMAGES[@]}"; do
	echo ""
	echo "Processing: $image"

	# Extract image name for filename (replace / and : with -)
	filename=$(echo "$image" | sed 's|/|-|g' | sed 's|:|_|g')
	tarfile="${IMAGES_DIR}/${filename}.tar"

	# Check if we need to update this image
	needs_update=false

	# Check if local image exists and get its ID
	local_image_id=$(docker images -q "$image" 2>/dev/null)

	if [[ -z "$local_image_id" ]]; then
		echo "  ↳ Image not found locally, pulling..."
		if docker pull "$image"; then
			echo "  ↳ Pull successful"
			needs_update=true
		else
			echo "  ❌ Failed to pull $image"
			exit 1
		fi
	else
		# Check if there's a newer version available
		echo "  ↳ Checking for updates..."
		if docker pull "$image"; then
			new_image_id=$(docker images -q "$image" 2>/dev/null)
			if [[ "$local_image_id" != "$new_image_id" ]]; then
				echo "  ↳ New version found, will update"
				needs_update=true
			else
				echo "  ↳ Image is up to date"
				# Check if tar file exists and is newer than a reasonable threshold
				if [[ -f "$tarfile" ]]; then
					echo "  ↳ Tar file already exists, skipping"
					size=$(du -h "$tarfile" | cut -f1)
					echo "  📦 Existing size: $size"
					continue
				else
					echo "  ↳ Tar file missing, will create"
					needs_update=true
				fi
			fi
		else
			echo "  ↳ Could not check for updates, using local image"
			if [[ -f "$tarfile" ]]; then
				echo "  ↳ Tar file already exists, skipping"
				size=$(du -h "$tarfile" | cut -f1)
				echo "  📦 Existing size: $size"
				continue
			else
				needs_update=true
			fi
		fi
	fi

	if [[ "$needs_update" == "true" ]]; then
		echo "  ↳ Saving to: $tarfile"
		if docker save -o "$tarfile" "$image"; then
			echo "  ✅ Saved successfully"
			# Show file size
			size=$(du -h "$tarfile" | cut -f1)
			echo "  📦 Size: $size"
		else
			echo "  ❌ Failed to save $image"
			exit 1
		fi
	fi
done

echo ""
echo "🎉 All images saved to: $IMAGES_DIR"
echo ""
echo "Files created:"
ls -lh "$IMAGES_DIR"/*.tar

echo ""
echo "Total size:"
du -sh "$IMAGES_DIR"

echo ""
print_images_info true
if [[ -s "$SCRIPT_DIR/strata/Dockerfile.local" ]] || docker image inspect qwen-strata-local:fb58e0d >/dev/null 2>&1; then
	bash "$SCRIPT_DIR/strata-image.sh" save
fi
echo ""
echo "Use ./load-docker-images.sh on offline systems to load these images"
