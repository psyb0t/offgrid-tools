#!/usr/bin/env bash
# Load Docker images from saved tar files for offline use

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/docker-images"

case "${1:-}" in
--strata-only)
	[[ $# == 1 ]] || exit 2
	exec bash "$SCRIPT_DIR/strata-image.sh" load
	;;
'') [[ $# == 0 ]] || exit 2 ;;
*)
	printf 'Usage: %s [--strata-only]\n' "$0" >&2
	exit 2
	;;
esac

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

		if [[ "$filename" == qwen-strata-local_fb58e0d.tar ]]; then
			bash "$SCRIPT_DIR/strata-image.sh" load
			load_status=$?
		else
			docker load -i "$tarfile"
			load_status=$?
		fi
		if [[ "$load_status" == 0 ]]; then
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
echo "📋 All loaded Docker images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

if [[ $failed_count -gt 0 ]]; then
	exit 1
else
	echo ""
	echo "🎉 All images loaded successfully!"
	echo ""
	echo "Quick start commands:"
	echo "  🚀 Start all services: docker-compose up"
	echo "  🔍 View all images: docker images"
	echo "  🐳 Run any container: docker run -it --rm <image_name>"
fi
