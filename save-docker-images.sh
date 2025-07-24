#!/usr/bin/env bash
# Save Docker images for offline distribution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/docker-images"

echo "=== Saving Docker Images for Offline Use ==="
echo "This will download and save the following images:"
echo "  📚 Kiwix server for offline content"
echo "  🤖 Ollama for local AI models"
echo "  🌐 Open WebUI for AI chat interface"
echo "  🎉 Ollama Chat Party for RAG-enabled chat"
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
    
    # AI/LLM server and UI
    "ollama/ollama:latest"          # Local AI model server
    "ghcr.io/open-webui/open-webui:main"  # Web UI for Ollama
    "psyb0t/ollama-chat-party:latest"      # RAG-enabled chat interface
    
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
    
    echo "  ↳ Pulling image..."
    if docker pull "$image"; then
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
    else
        echo "  ❌ Failed to pull $image"
        exit 1
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
echo "  🤖 Ollama: ollama/ollama:latest"
echo "  🌐 Open WebUI: ghcr.io/open-webui/open-webui:main"
echo "  🎉 Chat Party: psyb0t/ollama-chat-party:latest"
echo "  🐍 Python: python:3.12 (full)"
echo "  🐹 Go: golang:1.24 (full)"
echo "  🖥️  Base: ubuntu:22.04"
echo ""
echo "Use ./load-docker-images.sh on offline systems to load these images"