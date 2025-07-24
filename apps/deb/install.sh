#!/bin/bash

set -e

# Get script directory and detect OS info
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== DEB Package Offline Installation ==="

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

echo "🖥️  Detected system:"
echo "  OS: ${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
echo "  Architecture: ${ARCH}"
echo "  OS directory pattern: ${OS_DIR}"
echo ""

# Function to install packages from a specific directory
install_packages() {
    local pkg_dir="$1"
    local pkg_name=$(basename "$pkg_dir")
    local data_dir="${pkg_dir}/data/${OS_DIR}"
    
    echo "📦 Processing package group: $pkg_name"
    echo "  Looking in: $data_dir"
    
    # Check if OS-specific data directory exists
    if [[ ! -d "$data_dir" ]]; then
        echo "  ❌ No packages found for this OS"
        if [[ -d "${pkg_dir}/data" ]]; then
            echo "  Available OS directories:"
            ls -1 "${pkg_dir}/data/" 2>/dev/null | sed 's/^/    /'
        fi
        return 1
    fi
    
    # Check if there are any .deb files
    if ! ls "$data_dir"/*.deb >/dev/null 2>&1; then
        echo "  ❌ No .deb files found in: $data_dir"
        return 1
    fi
    
    echo "  Found .deb packages:"
    ls -lh "$data_dir"/*.deb | sed 's/^/    /'
    echo ""
    
    # Check installation status first
    echo "  🔍 Checking installation status..."
    local installed_count=0
    local skipped_count=0
    local failed_count=0
    
    # Temporarily disable exit on error for the package processing
    set +e
    
    for debfile in "$data_dir"/*.deb; do
        if [[ -f "$debfile" ]]; then
            filename=$(basename "$debfile")
            # Extract package name from filename  
            pkg_name_extracted=$(echo "$filename" | cut -d'_' -f1)
            
            echo "    Processing: $filename"
            
            # Check if already installed
            if dpkg -l "$pkg_name_extracted" 2>/dev/null | grep -q "^ii"; then
                echo "      ⏭️  Already installed, skipping"
                ((skipped_count++))
            else
                echo "      📦 Installing..."
                
                sudo dpkg -i "$debfile" 2>/dev/null
                dpkg_result=$?
                
                if [[ $dpkg_result -eq 0 ]]; then
                    echo "      ✅ Installed successfully"
                    ((installed_count++))
                else
                    echo "      ❌ Failed to install $filename"
                    ((failed_count++))
                fi
            fi
        fi
    done
    
    # Re-enable exit on error
    set -e
    
    # Fix any dependency issues
    if [[ $failed_count -gt 0 ]]; then
        echo "  🔧 Fixing dependency issues..."
        sudo apt-get install -f -y
    fi
    
    echo "  📊 Summary for $pkg_name:"
    echo "    ✅ Installed: $installed_count packages"
    echo "    ⏭️  Skipped: $skipped_count packages"
    if [[ $failed_count -gt 0 ]]; then
        echo "    ❌ Failed: $failed_count packages"
    fi
    echo ""
    
    return 0
}

# Parse arguments
if [[ $# -gt 0 ]]; then
    # Install specific package group
    target_pkg="$1"
    target_dir="${SCRIPT_DIR}/${target_pkg}"
    
    if [[ ! -d "$target_dir" ]]; then
        echo "❌ Package directory not found: $target_pkg"
        echo ""
        echo "Available package directories:"
        find "$SCRIPT_DIR" -maxdepth 1 -type d -name "*" ! -name "." | grep -v "^${SCRIPT_DIR}$" | sed "s|${SCRIPT_DIR}/||" | sed 's/^/  /'
        exit 1
    fi
    
    echo "🎯 Installing specific package group: $target_pkg"
    echo ""
    
    if install_packages "$target_dir"; then
        echo "🎉 Installation of $target_pkg completed!"
    else
        echo "❌ Installation of $target_pkg failed or no packages found"
        exit 1
    fi
else
    # Install all available packages
    echo "🔍 Scanning for available package directories..."
    
    found_packages=false
    successful_installs=0
    failed_installs=0
    
    for pkg_dir in "$SCRIPT_DIR"/*; do
        if [[ -d "$pkg_dir" && -d "${pkg_dir}/data" ]]; then
            found_packages=true
            pkg_name=$(basename "$pkg_dir")
            
            if install_packages "$pkg_dir"; then
                ((successful_installs++))
            else
                ((failed_installs++))
            fi
        fi
    done
    
    if [[ "$found_packages" == "false" ]]; then
        echo "❌ No package directories found with data subdirectories"
        echo ""
        echo "Expected structure:"
        echo "  apps/deb/"
        echo "  ├── package1/"
        echo "  │   └── data/"
        echo "  │       └── ${OS_DIR}/"
        echo "  │           └── *.deb"
        echo "  └── package2/"
        echo "      └── data/"
        echo "          └── ${OS_DIR}/"
        echo "              └── *.deb"
        exit 1
    fi
    
    echo "=== Final Summary ==="
    echo "✅ Successfully processed: $successful_installs package groups"
    if [[ $failed_installs -gt 0 ]]; then
        echo "❌ Failed or no packages: $failed_installs package groups"
    fi
    
    if [[ $failed_installs -gt 0 ]]; then
        exit 1
    else
        echo ""
        echo "🎉 All available packages processed successfully!"
    fi
fi

echo ""
echo "Usage examples:"
echo "  ./install.sh          # Install all available packages"
echo "  ./install.sh docker   # Install only docker packages"
echo "  ./install.sh someapp  # Install only someapp packages"