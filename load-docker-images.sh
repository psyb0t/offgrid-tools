#!/usr/bin/env bash
# Load Docker images from saved tar files for offline use

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/docker-images"

echo "=== Loading Docker Images from Offline Archive ==="

# Check if images directory exists
if [[ ! -d "$IMAGES_DIR" ]]; then
    echo "❌ Images directory not found: $IMAGES_DIR"
    echo "Run ./save-docker-images.sh first to create the archive"
    exit 1
fi

# Check if there are any tar files
if ! ls "$IMAGES_DIR"/*.tar >/dev/null 2>&1; then
    echo "❌ No .tar files found in: $IMAGES_DIR"
    echo "Run ./save-docker-images.sh first to save images"
    exit 1
fi

echo "Found Docker image archives:"
ls -lh "$IMAGES_DIR"/*.tar
echo ""

# Load each tar file
loaded_count=0
failed_count=0

for tarfile in "$IMAGES_DIR"/*.tar; do
    if [[ -f "$tarfile" ]]; then
        filename=$(basename "$tarfile")
        echo "Loading: $filename"
        
        if docker load -i "$tarfile"; then
            echo "  ✅ Loaded successfully"
            ((loaded_count++))
        else
            echo "  ❌ Failed to load $filename"
            ((failed_count++))
        fi
        echo ""
    fi
done

echo "=== Summary ==="
echo "✅ Successfully loaded: $loaded_count images"
if [[ $failed_count -gt 0 ]]; then
    echo "❌ Failed to load: $failed_count images"
fi

echo ""
echo "Available images:"
echo "📚 Kiwix server:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|kiwix)" || echo "  No kiwix images found"
echo ""
echo "🤖 Ollama AI server:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|ollama)" | grep -v "chat-party" || echo "  No ollama images found"
echo ""
echo "🌐 Open WebUI:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|open-webui)" || echo "  No open-webui images found"
echo ""
echo "🎉 Ollama Chat Party:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|ollama-chat-party)" || echo "  No ollama-chat-party images found"
echo ""
echo "🐍 Python images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|python)" || echo "  No python images found"
echo ""
echo "🐹 Go images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|golang)" || echo "  No golang images found"
echo ""
echo "🖥️  Base OS images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|ubuntu)" || echo "  No base OS images found"

if [[ $failed_count -gt 0 ]]; then
    exit 1
else
    echo ""
    echo "🎉 All images loaded successfully!"
    echo ""
    echo "Quick start commands:"
    echo "  🌐 Start Kiwix server: docker-compose up kiwix"
    echo "  🤖 Start Ollama AI server: docker-compose up ollama"
    echo "  💬 Start AI chat UI: docker-compose up openwebui"
    echo "  🎉 Start RAG chat UI: docker-compose up ollama-chat-party"
    echo "  🚀 Start all services: docker-compose up"
    echo "  🐍 Run Python container: docker run -it --rm python:3.12"
    echo "  🐹 Run Go container: docker run -it --rm golang:1.24"
    echo "  🖥️  Run Ubuntu container: docker run -it --rm ubuntu:22.04"
fi