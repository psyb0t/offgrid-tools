#!/bin/bash

set -e

# Clean slate (optional: comment this out if you don't want to wipe the cache)
sudo apt-get clean
sudo rm -rf /var/cache/apt/archives/*.deb

# Prep keyring and repo
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Get script directory and detect OS info
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS version and architecture
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
echo "  Data directory: ${DATA_DIR}"
echo ""

# Create output dir (clean up if exists)
if [[ -d "$DATA_DIR" ]]; then
    echo "🧹 Cleaning up existing data directory for this OS..."
    rm -rf "$DATA_DIR"
fi
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# Simulate install to find required packages
echo "🔍 Finding required Docker packages..."
REQUIRED=$(apt-get --print-uris install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin 2>/dev/null | \
  grep "^'" | cut -d"'" -f2)

echo "📦 Found packages to download:"
echo "$REQUIRED"
echo ""

if [[ -z "$REQUIRED" ]]; then
    echo "❌ No packages found to download. This might happen if:"
    echo "   - Docker is already installed"
    echo "   - Package names have changed"
    echo "   - Repository is not properly configured"
    echo ""
    echo "🔧 Trying alternative approach..."
    
    # Alternative: use apt-cache to find packages and download manually
    PACKAGES="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    for pkg in $PACKAGES; do
        echo "Checking package: $pkg"
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            echo "  ↳ Found $pkg, downloading..."
            apt-get download "$pkg" 2>/dev/null || echo "  ❌ Failed to download $pkg"
        else
            echo "  ❌ Package $pkg not found"
        fi
    done
else
    # Download only those packages
    for url in $REQUIRED; do
        echo "Downloading: $url"
        wget -q "$url" || echo "❌ Failed to download $url"
    done
fi

# Show what was actually downloaded
echo ""
echo "📊 Download Summary:"
if ls *.deb >/dev/null 2>&1; then
    echo "✅ Successfully downloaded packages:"
    ls -lh *.deb
    echo ""
    echo "📦 Total size:"
    du -sh .
else
    echo "❌ No .deb files were downloaded!"
    echo "This could indicate an issue with the download process."
fi

echo ""
echo "📁 Files are saved in: $(pwd)"
