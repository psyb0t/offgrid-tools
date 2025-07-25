#!/usr/bin/env bash
# Save Docker images for offline distribution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/docker-images"

echo "=== Saving Docker Images for Offline Use ==="
echo "This will download and save the following images:"
echo "  📚 Kiwix server for offline content"
echo "  🌐 Zimit for web content archiving"
echo "  🤖 Ollama for local AI models"
echo "  🌐 Open WebUI for AI chat interface"
echo "  🎉 Ollama Chat Party for RAG-enabled chat"
echo "  💬 TheLounge for web-based IRC client"
echo "  🌐 InspIRCd for IRC server hosting"
echo "  🐍 Python runtime (full version)"
echo "  🐹 Go development environment (full version)"
echo "  🖥️  Ubuntu base OS for containers"
echo ""

# Create images directory if it doesn't exist
mkdir -p "$IMAGES_DIR"

# List of images to save
IMAGES=(
    # Offline content server
    "ghcr.io/kiwix/kiwix-serve:latest"
    "ghcr.io/openzim/zimit:latest"  # Web content archiving tool
    
    # AI/LLM server and UI
    "ollama/ollama:latest"          # Local AI model server
    "ghcr.io/open-webui/open-webui:main"  # Web UI for Ollama
    "psyb0t/ollama-chat-party:latest"      # RAG-enabled chat interface
    
    # IRC chat network
    "thelounge/thelounge:latest"    # Web-based IRC client
    "inspircd/inspircd-docker:latest"      # IRC server
    
    # Programming language runtimes (full versions)
    "python:3.12"                   # Latest stable Python (full)
    "golang:1.24"                   # Latest stable Go (full)
    
    # Base operating system for development
    "ubuntu:22.04"                  # LTS Ubuntu for general development
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
        echo "  ↳ Image not found locally, will pull"
        needs_update=true
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
echo "📋 Available images for offline use:"
echo "  📚 Kiwix: ghcr.io/kiwix/kiwix-serve:latest"
echo "  🌐 Zimit: ghcr.io/openzim/zimit:latest"
echo "  🤖 Ollama: ollama/ollama:latest"
echo "  🌐 Open WebUI: ghcr.io/open-webui/open-webui:main"
echo "  🎉 Chat Party: psyb0t/ollama-chat-party:latest"
echo "  💬 TheLounge: thelounge/thelounge:latest"
echo "  🌐 InspIRCd: inspircd/inspircd-docker:latest"
echo "  🐍 Python: python:3.12 (full)"
echo "  🐹 Go: golang:1.24 (full)"
echo "  🖥️  Base: ubuntu:22.04"
echo ""
echo "Use ./load-docker-images.sh on offline systems to load these images"