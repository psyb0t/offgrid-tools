#!/bin/bash

set -e

echo "=== DEB Package Offline Installation ==="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Setup OS detection
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS_NAME="${ID}"
    OS_VERSION="${VERSION_ID}"
    OS_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME}}"
else
    echo "❌ Could not detect OS version from /etc/os-release"
    exit 1
fi

ARCH=$(dpkg --print-architecture)
OS_DIR="${OS_NAME}-${OS_VERSION}-${ARCH}"
DATA_DIR="${SCRIPT_DIR}/data/${OS_DIR}"

echo "🖥️  Detected system:"
echo "  OS: ${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
echo "  Architecture: ${ARCH}"
echo "  Looking for packages in: ${DATA_DIR}"
echo ""

# Check if data directory exists
if [[ ! -d "$DATA_DIR" ]]; then
    echo "❌ No packages found for this OS: $OS_DIR"
    if [[ -d "${SCRIPT_DIR}/data" ]]; then
        echo ""
        echo "Available OS directories:"
        ls -1 "${SCRIPT_DIR}/data/" 2>/dev/null | sed 's/^/  /'
    fi
    echo ""
    echo "Run ./download.sh first to download packages for your system"
    exit 1
fi

# Check if there are any .deb files
if ! ls "$DATA_DIR"/*.deb >/dev/null 2>&1; then
    echo "❌ No .deb files found in: $DATA_DIR"
    echo ""
    echo "Run ./download.sh first to download packages"
    exit 1
fi

echo "📦 Found .deb packages:"
ls -lh "$DATA_DIR"/*.deb | sed 's/^/  /'
echo ""

# Installation process
echo "🚀 Starting installation..."
echo ""

installed_count=0
skipped_count=0
failed_count=0

# Temporarily disable exit on error for package processing
set +e

for debfile in "$DATA_DIR"/*.deb; do
    if [[ -f "$debfile" ]]; then
        filename=$(basename "$debfile")
        # Extract package name from filename  
        pkg_name=$(echo "$filename" | cut -d'_' -f1)
        
        echo "📦 Processing: $filename"
        
        # Check if already installed
        if dpkg -l "$pkg_name" 2>/dev/null | grep -q "^ii"; then
            echo "  ⏭️  Already installed, skipping"
            ((skipped_count++))
        else
            echo "  🔧 Installing..."
            
            sudo dpkg -i "$debfile" 2>/dev/null
            dpkg_result=$?
            
            if [[ $dpkg_result -eq 0 ]]; then
                echo "  ✅ Installed successfully"
                ((installed_count++))
            else
                echo "  ❌ Failed to install (dependencies may be missing)"
                ((failed_count++))
            fi
        fi
        echo ""
    fi
done

# Re-enable exit on error
set -e

# Fix any dependency issues
if [[ $failed_count -gt 0 ]]; then
    echo "🔧 Fixing dependency issues..."
    sudo apt-get install -f -y
    echo ""
fi

echo "📊 Installation Summary:"
echo "  ✅ Installed: $installed_count packages"
echo "  ⏭️  Skipped: $skipped_count packages (already installed)"
if [[ $failed_count -gt 0 ]]; then
    echo "  ❌ Failed: $failed_count packages"
fi
echo ""

if [[ $installed_count -gt 0 ]]; then
    echo "🎉 Installation completed! Installed $installed_count new packages."
elif [[ $skipped_count -gt 0 ]]; then
    echo "✅ All packages were already installed."
else
    echo "❌ No packages were installed."
    exit 1
fi

echo ""
echo "Available tools should now be installed:"
echo "  🐳 Docker: docker, docker-compose"
echo "  📱 ADB: adb, fastboot"