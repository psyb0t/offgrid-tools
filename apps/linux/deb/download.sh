#!/bin/bash

# Get script directory first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up logging first - start fresh each time
LOG_FILE="$SCRIPT_DIR/download.sh.log"
> "$LOG_FILE"  # Clear the log file

# Custom log function that writes to both stdout and file
log() {
    echo "$@"
    echo "$@" >> "$LOG_FILE"
}

# Parse command line arguments
MAX_JOBS=10  # Default value
if [[ $# -gt 0 ]]; then
    if [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -gt 0 ]]; then
        MAX_JOBS="$1"
    else
        log "Usage: $0 [max_parallel_jobs]"
        log "  max_parallel_jobs: Number of concurrent downloads (default: 10, must be positive integer)"
        exit 1
    fi
fi

log "=== Downloading All Linux Packages ==="
log "Log file: $LOG_FILE"
log "Started at: $(date)"
log ""
log "This will download and save the following package groups:"
log "  🐳 Docker - container runtime and development tools"
log "  📱 Android tools - adb, vysor"
log "  📝 Text editor - nano"
log "  🔨 Development tools - go, python, php, geany, build-essential, gcc, g++, make, cmake, gdb, valgrind"
log "  🌐 Web server - nginx"
log "  💻 Terminal emulator - terminator"
log "  🖥️  VirtualBox - virtualization platform"
log "  🌐 Chromium - web browser"
log "  🎨 GIMP - image editor"
log "  🎬 FFmpeg - multimedia framework"
log "  ⚙️  Supervisor - process control system"
log "  📊 System monitoring - htop, iotop, nethogs"
log "  🔍 Network tools - wireshark, nmap, netcat"
log "  📁 File sync & backup - rsync, borgbackup, vorta"
log "  📻 Software Defined Radio - gqrx-sdr"
log "  🎵 Audio streaming - butt, mixxx"
log "  🔒 Security - ufw, keepassxc, ssh client/server"
log "  💾 Disk tools - testdisk, gparted, ntfs-3g, gddrescue, gnome-disks"
log "  🛠️  System utilities - pv progress viewer"
log ""

# Check Docker availability first
if ! command -v docker &> /dev/null; then
    log "❌ Docker is not installed or not in PATH"
    log "This script requires Docker to create a clean Ubuntu environment for package resolution."
    log "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    log "❌ Docker daemon is not running or not accessible"
    log "Please start Docker daemon or check Docker permissions"
    exit 1
fi

log "✅ Docker is available and running"
log ""

# Detect OS version and architecture
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS_NAME="${ID}"
    OS_VERSION="${VERSION_ID}"
    OS_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME}}"
else
    log "❌ Could not detect OS version from /etc/os-release"
    exit 1
fi

ARCH=$(dpkg --print-architecture)
OS_DIR="${OS_NAME}-${OS_VERSION}-${ARCH}"
DATA_DIR="${SCRIPT_DIR}/data/${OS_DIR}"

log "🖥️  Detected system:"
log "  OS: ${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
log "  Architecture: ${ARCH}"
log "  Data directory: ${DATA_DIR}"
log "  Max parallel downloads: ${MAX_JOBS}"
log ""

# Create output dir and handle existing files
mkdir -p "$DATA_DIR"

# Check if data directory has .deb files
if [[ -d "$DATA_DIR" ]] && ls "$DATA_DIR"/*.deb >/dev/null 2>&1; then
    existing_count=$(ls "$DATA_DIR"/*.deb 2>/dev/null | wc -l)
    log "📦 Found $existing_count existing .deb files in data directory"
    read -p "Do you want to start fresh (delete existing files)? y/N: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "🧹 Cleaning up existing data directory..."
        rm -rf "$DATA_DIR"/*.deb 2>/dev/null || true
        log "✅ Data directory cleaned"
    else
        log "✅ Keeping existing files - will skip downloading duplicates"
    fi
fi

cd "$DATA_DIR"

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    log "❌ Docker not found. Install Docker first."
    exit 1
fi

# Define ALL packages to check individually
PACKAGES=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
    "android-tools-adb"
    "android-tools-fastboot"
    "android-sdk-platform-tools-common"
    "golang-go"
    "python3"
    "python3-pip"
    "python3-venv"
    "nano"
    "chromium-browser"
    "gimp"
    "geany"
    "terminator"
    "supervisor"
    "virtualbox-7.1"
    "ffmpeg"
    "htop"
    "iotop"
    "nethogs"
    "wireshark"
    "nmap"
    "rsync"
    "borgbackup"
    "vorta"
    "gqrx-sdr"
    "butt"
    "mixxx"
    "ufw"
    "testdisk"
    "gparted"
    "ntfs-3g"
    "gddrescue"
    "gnome-disk-utility"
    "vysor"
    "pv"
    "keepassxc"
    "openssh-client"
    "openssh-server"
    "netcat-openbsd"
    "build-essential"
    "gcc"
    "g++"
    "make"
    "cmake"
    "gdb"
    "valgrind"
    "pkg-config"
    "libc6-dev"
    "nginx"
    "php"
    "php-fpm"
    "php-cli"
)

log "🐳 Starting clean Docker container in background..."

# Use Ubuntu base image
docker_image="${OS_NAME}:${OS_VERSION}"
log "🖥️  Using Ubuntu base image: $docker_image"

container_name="offgrid-tools-deb-downloader"

# Start container in background
docker run -d --name "$container_name" "$docker_image" sleep 3600 >/dev/null

# Track background processes
bg_pids=()

# Track if cleanup has already run
cleanup_done=false

# Function to cleanup container and kill background jobs on exit
cleanup() {
    # Prevent duplicate cleanup
    if [[ "$cleanup_done" == "true" ]]; then
        return
    fi
    cleanup_done=true

    log ""
    log "🛑 Stopping downloads and cleaning up..."

    # Kill tracked background processes
    if [[ ${#bg_pids[@]} -gt 0 ]]; then
        log "Stopping ${#bg_pids[@]} background processes..."
        for pid in "${bg_pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                kill -TERM "$pid" 2>/dev/null || true
                sleep 1
                kill -KILL "$pid" 2>/dev/null || true
            fi
        done
    fi

    # Kill any remaining processes
    pkill -f "wget.*\.deb" 2>/dev/null || true
    pkill -f "xargs.*download_file" 2>/dev/null || true
    pkill -f "parallel.*download_file" 2>/dev/null || true

    # Clean up Docker container
    if [[ -n "$container_name" ]]; then
        log "🧹 Cleaning up Docker container: $container_name"
        if docker ps -q -f name="$container_name" | grep -q .; then
            docker kill "$container_name" 2>/dev/null || true
            sleep 1
        fi
        docker rm -f "$container_name" 2>/dev/null || true
    fi

    # Clean up temp files
    [[ -n "$temp_file" ]] && rm -f "$temp_file" 2>/dev/null || true
    rm -f "/tmp/package_urls_$$" 2>/dev/null || true
    rm -f "$SUCCESS_FILE" "$FAILED_FILE" "$SKIPPED_FILE" 2>/dev/null || true

    log "Session interrupted at: $(date)"
    exit 130
}
# Simple trap - tee was interfering with signals
trap cleanup INT TERM

log "📋 Setting up repositories in container..."

# Make sure we can still interrupt during container setup

# Setup repositories in the container
log "🔧 Setting up APT repositories..."

# Run each docker exec command separately so we can see progress
log "📦 Running apt-get update..."
docker exec "$container_name" apt-get update >/dev/null 2>&1

log "🔧 Installing prerequisites..."
docker exec "$container_name" apt-get install -y ca-certificates curl gnupg software-properties-common wget >/dev/null 2>&1
docker exec "$container_name" mkdir -p /etc/apt/keyrings >/dev/null 2>&1

log "🐳 Setting up Docker repository..."
docker exec "$container_name" curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc >/dev/null 2>&1
docker exec "$container_name" chmod a+r /etc/apt/keyrings/docker.asc >/dev/null 2>&1
docker exec "$container_name" bash -c "echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $OS_CODENAME stable' > /etc/apt/sources.list.d/docker.list" >/dev/null 2>&1

log "🐹 Setting up Go PPA..."
docker exec "$container_name" add-apt-repository -y ppa:longsleep/golang-backports >/dev/null 2>&1

log "📦 Setting up VirtualBox repository..."
docker exec "$container_name" wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc 2>/dev/null | docker exec -i "$container_name" gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg >/dev/null 2>&1
docker exec "$container_name" bash -c "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $OS_CODENAME contrib' > /etc/apt/sources.list.d/virtualbox.list" >/dev/null 2>&1

log "📱 Setting up Vysor repository..."
docker exec "$container_name" bash -c "echo 'deb [arch=amd64 trusted=yes] https://nuts.vysor.io/apt ./' > /etc/apt/sources.list.d/vysor.list" >/dev/null 2>&1

log "🔄 Final apt-get update..."
docker exec "$container_name" apt-get update >/dev/null 2>&1
log "✅ Repository setup complete!"

# Repository setup is complete (commands ran synchronously)

# Package checking loop - handle errors manually

log "🔍 Checking packages individually for dependency resolution..."
log "📊 Total packages to check: ${#PACKAGES[@]}"

successful_packages=()
failed_packages=()
all_urls=()

# Check each package individually
package_count=0
for package in "${PACKAGES[@]}"; do
    ((package_count++))
    log "  [$package_count/${#PACKAGES[@]}] Checking $package..."

    # Step 1: Test if package exists
    log "    → Checking if $package exists..."
    docker exec "$container_name" apt-cache show "$package" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        log "  [$package_count/${#PACKAGES[@]}] ❌ $package - package not found"
        failed_packages+=("$package")
        continue
    fi
    log "    → Package exists"

    # Step 2: Get raw apt-get output
    log "    → Getting download URLs..."
    temp_raw="/tmp/raw_apt_$$"
    docker exec "$container_name" apt-get --print-uris --yes --reinstall install "$package" > "$temp_raw" 2>&1
    if [[ $? -ne 0 ]]; then
        log "  [$package_count/${#PACKAGES[@]}] ❌ $package - apt-get failed"
        log "    → Error: $(head -3 "$temp_raw" | tail -1)"
        failed_packages+=("$package")
        rm -f "$temp_raw"
        continue
    fi

    # Step 3: Extract URLs from output
    temp_urls="/tmp/urls_$$"
    grep "^'" "$temp_raw" > "$temp_urls" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        log "  [$package_count/${#PACKAGES[@]}] ❌ $package - no download URLs found in output"
        log "    → Debug: First 3 lines of apt-get output:"
        head -3 "$temp_raw" | sed 's/^/    → /'
        failed_packages+=("$package")
        rm -f "$temp_raw" "$temp_urls"
        continue
    fi

    # Step 4: Clean URLs
    temp_clean="/tmp/clean_$$"
    cut -d"'" -f2 "$temp_urls" > "$temp_clean" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        log "  [$package_count/${#PACKAGES[@]}] ❌ $package - failed to extract URLs"
        failed_packages+=("$package")
        rm -f "$temp_raw" "$temp_urls" "$temp_clean"
        continue
    fi

    # Show URL count
    if [[ -s "$temp_clean" ]]; then
        url_count=$(wc -l < "$temp_clean")
        log "    → Found $url_count download URLs"
    fi


    # Step 5: Verify we got URLs
    if [[ -s "$temp_clean" ]]; then
        url_count=$(wc -l < "$temp_clean")
        log "  [$package_count/${#PACKAGES[@]}] ✅ $package resolved successfully ($url_count URLs)"
        successful_packages+=("$package")
        # Add URLs to our collection
        while IFS= read -r url; do
            [[ -n "$url" ]] && all_urls+=("$url")
        done < "$temp_clean"
    else
        log "  [$package_count/${#PACKAGES[@]}] ❌ $package - no clean URLs extracted"
        failed_packages+=("$package")
    fi

    # Cleanup
    rm -f "$temp_raw" "$temp_urls" "$temp_clean"

    # Clean up temp file
    rm -f "/tmp/package_urls_$$" 2>/dev/null
done

# Remove duplicate URLs
log ""
log "🔧 Removing duplicate package URLs..."
declare -A seen_urls
unique_urls=()
for url in "${all_urls[@]}"; do
    if [[ -z "${seen_urls[$url]}" ]]; then
        seen_urls[$url]=1
        unique_urls+=("$url")
    fi
done

log "📊 Package Analysis Summary:"
log "  ✅ Successfully resolved: ${#successful_packages[@]} packages"
log "  ❌ Failed to resolve: ${#failed_packages[@]} packages"
log "  📦 Total unique packages to download: ${#unique_urls[@]}"
log ""

if [[ ${#successful_packages[@]} -eq 0 ]]; then
    log "❌ No packages could be resolved. Check your repositories and network connection."
    exit 1
fi

# Clean up Docker container now that we have all URLs
log "🧹 Cleaning up Docker container (no longer needed)..."
docker stop "$container_name" >/dev/null 2>&1 || true
docker rm "$container_name" >/dev/null 2>&1 || true
container_name=""  # Clear so cleanup function doesn't try again

log "✅ Successfully resolved packages:"
for pkg in "${successful_packages[@]}"; do
    log "  • $pkg"
done

if [[ ${#failed_packages[@]} -gt 0 ]]; then
    log ""
    log "❌ Failed packages (will be skipped):"
    for pkg in "${failed_packages[@]}"; do
        log "  • $pkg"
    done
fi

log ""
log "🚀 Starting parallel download of ${#unique_urls[@]} packages..."

# Temporarily disable exit on error for downloads
set +e

# Create temp files for tracking results
mkdir -p /tmp/offgrid-tools
SUCCESS_FILE="/tmp/offgrid-tools/.apps-linux-deb-download-success"
FAILED_FILE="/tmp/offgrid-tools/.apps-linux-deb-download-failed"
SKIPPED_FILE="/tmp/offgrid-tools/.apps-linux-deb-download-skipped"

# Clear previous results
> "$SUCCESS_FILE"
> "$FAILED_FILE"
> "$SKIPPED_FILE"

# Create a function to download a single file
download_file() {
    local url="$1"
    local index="$2"
    local total="$3"
    local filename=$(basename "$url")

    # Decode URL-encoded filename for local storage (proper URL decoding)
    local decoded_filename=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$filename'))" 2>/dev/null || echo "$filename")

    # Check if file already exists (try both encoded and decoded names)
    if [[ -f "$filename" ]] || [[ -f "$decoded_filename" ]]; then
        # Use log function for download status
        log "[$index/$total] ⏭️  $url -> $decoded_filename (already exists)"
        echo "$decoded_filename" >> "$SKIPPED_FILE"
        return 0
    fi

    # Use wget with timeout and retry options, save with decoded filename
    local wget_output
    wget_output=$(timeout 300 wget --quiet --tries=3 --timeout=60 -O "$decoded_filename" "$url" 2>&1)
    local wget_result=$?

    if [[ $wget_result -eq 0 ]]; then
        log "[$index/$total] ✅ $url -> $decoded_filename"
        echo "$decoded_filename" >> "$SUCCESS_FILE"
        return 0
    else
        # Clean up partial download
        rm -f "$decoded_filename" 2>/dev/null

        # Provide better error reporting
        if [[ $wget_result -eq 124 ]]; then
            log "[$index/$total] ❌ $url (timeout)"
        elif echo "$wget_output" | grep -q "404\|not found"; then
            log "[$index/$total] ❌ $url (404 not found)"
        elif echo "$wget_output" | grep -q "Name or service not known"; then
            log "[$index/$total] ❌ $url (DNS error)"
        else
            log "[$index/$total] ❌ $url (exit code: $wget_result)"
        fi
        echo "$decoded_filename" >> "$FAILED_FILE"
        return 1
    fi
}

# Export functions so they're available to parallel processes
export -f download_file
export -f log
export LOG_FILE SUCCESS_FILE FAILED_FILE SKIPPED_FILE

# Download all URLs in parallel with limited concurrent jobs
total_urls=${#unique_urls[@]}

log "Starting parallel downloads (max $MAX_JOBS concurrent)..."

# Create a temporary file to store URLs with indices
temp_file=$(mktemp)
for i in "${!unique_urls[@]}"; do
    echo "${unique_urls[$i]} $((i + 1)) $total_urls" >> "$temp_file"
done

# Use xargs to run downloads in parallel
if command -v parallel >/dev/null 2>&1; then
    # Use GNU parallel if available (better performance)
    log "Using GNU parallel for downloads..."
    log "Press CTRL+C to stop downloads..."
    parallel -j "$MAX_JOBS" --colsep ' ' download_file {1} {2} {3} :::: "$temp_file" &
    parallel_pid=$!
    bg_pids+=("$parallel_pid")
    wait $parallel_pid
else
    # Fallback to xargs with parallel processing
    log "Using xargs for parallel downloads..."
    log "Press CTRL+C to stop downloads..."
    cat "$temp_file" | xargs -n 3 -P "$MAX_JOBS" bash -c 'download_file "$1" "$2" "$3"' _ &
    xargs_pid=$!
    bg_pids+=("$xargs_pid")
    wait $xargs_pid
fi

# Clean up temp file
rm -f "$temp_file"

# Count download results from temp files (ignore empty lines)
download_success=0
download_skipped=0
download_failed=0

[[ -f "$SUCCESS_FILE" ]] && download_success=$(wc -l < "$SUCCESS_FILE" 2>/dev/null | tr -d ' ')
[[ -f "$SKIPPED_FILE" ]] && download_skipped=$(wc -l < "$SKIPPED_FILE" 2>/dev/null | tr -d ' ')
[[ -f "$FAILED_FILE" ]] && download_failed=$(wc -l < "$FAILED_FILE" 2>/dev/null | tr -d ' ')

# Count total files we have now
total_files=$(ls *.deb 2>/dev/null | wc -l || echo 0)

# Clean up temp files
rm -f "$SUCCESS_FILE" "$FAILED_FILE" "$SKIPPED_FILE" 2>/dev/null || true

# Re-enable exit on error
set -e

# Show download summary
log ""
log "📊 Download Summary:"
if ls *.deb >/dev/null 2>&1; then
    log "✅ .deb packages available:"
    ls -lh *.deb
    log ""
    log "📦 Total directory size:"
    du -sh .
else
    log "❌ No .deb files found!"
fi

log ""
log "📁 Files are saved in: $(pwd)"
log ""
log "📋 Final Summary:"
log "  ✅ Packages resolved: ${#successful_packages[@]}/${#PACKAGES[@]}"
log "  📦 Total .deb files: $total_files"
log ""
log "📥 Download Results:"
log "  ✅ Downloaded: $download_success"
log "  ⏭️  Skipped (already existed): $download_skipped"
log "  ❌ Failed: $download_failed"

if [[ ${#failed_packages[@]} -gt 0 ]]; then
    log ""
    log "⚠️  The following packages could not be resolved and were skipped:"
    for pkg in "${failed_packages[@]}"; do
        log "    • $pkg - check if package name is correct or repository is available"
    done
fi

# Only show package info if we actually have successful packages
if [[ ${#successful_packages[@]} -gt 0 ]] && [[ $total_files -gt 0 ]]; then
    log ""
    log "📋 Successfully downloaded packages are ready for offline use:"
    log "   Run ./install.sh to install them"
elif [[ ${#successful_packages[@]} -gt 0 ]]; then
    log ""
    log "⚠️  Package dependency resolution succeeded but downloads failed."
    log "   This may be due to outdated repository package versions."
    log "   Run the script again - repositories may have updated."
else
    log ""
    log "❌ No packages were successfully processed."
    log "   Check your internet connection and repository access."
fi

# Only show completion if not interrupted
if [[ "$cleanup_done" != "true" ]]; then
    log ""
    log "Session completed at: $(date)"
    log "Full log saved to: $LOG_FILE"
fi
