#!/bin/bash

# Shared utilities for Linux package downloading scripts
# Source this file in download scripts: source ../../utils.sh

# Simple function: get URLs from clean Docker container, download on host
download_packages_with_docker() {
    local packages=("$@")
    local setup_cmd="${DOCKER_SETUP_CMD:-}"
    
    echo "🐳 Using clean Docker container to get package URLs..."
    local docker_image="${OS_NAME}:${OS_VERSION}"
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker not found. Install Docker first or run manually."
        exit 1
    fi
    
    # Build package list for apt command
    local package_list="${packages[*]}"
    
    echo "📋 Getting URLs from clean $docker_image container..."
    
    # Get URLs from clean container with optional setup
    echo "🔧 Running Docker container command..."
    
    # Build the Docker command more carefully
    echo "Debug: Running command in $docker_image"
    
    if [[ -n "$setup_cmd" ]]; then
        echo "Debug: Will run setup command first"
        REQUIRED=$(docker run --rm "$docker_image" bash -c "
            set -e
            apt-get update >/dev/null 2>&1
            $setup_cmd >/dev/null 2>&1
            apt-get --print-uris --yes install $package_list 2>/dev/null | grep \"^'\" | cut -d\"'\" -f2
        ")
    else
        echo "Debug: No setup command, running basic apt"
        REQUIRED=$(docker run --rm "$docker_image" bash -c "
            set -e
            apt-get update >/dev/null 2>&1
            apt-get --print-uris --yes install $package_list 2>/dev/null | grep \"^'\" | cut -d\"'\" -f2
        ")
    fi
    
    if [[ -n "$REQUIRED" ]]; then
        echo "📦 Found packages to download:"
        echo "$REQUIRED"
        echo ""
        
        # Download the DEBs on host
        for url in $REQUIRED; do
            echo "Downloading: $url"
            wget -q "$url" || echo "❌ Failed to download $url"
        done
    else
        echo "❌ No packages found or Docker command failed"
        exit 1
    fi
}


# Common function to show download summary
show_download_summary() {
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
}

# Common function to setup data directory
setup_data_directory() {
    local script_dir="$1"
    
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
    DATA_DIR="${script_dir}/data/${OS_DIR}"
    
    echo "🖥️  Detected system:"
    echo "  OS: ${OS_NAME} ${OS_VERSION} (${OS_CODENAME:-unknown})"
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
    
    # Export variables for use in calling script
    export OS_NAME OS_VERSION OS_CODENAME ARCH OS_DIR DATA_DIR
}

# Common function for repository setup (Docker-specific)
setup_docker_repository() {
    echo "🔧 Setting up Docker repository..."
    
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
}