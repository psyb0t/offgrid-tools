#!/bin/bash

set -e

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                    Android APK Installer                      ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}            Install APKs via ADB to connected device           ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_installing() {
    echo -e "${PURPLE}📱 $1${NC}"
}

# Function to check if ADB is available and device is connected
check_adb() {
    if ! command -v adb >/dev/null 2>&1; then
        print_error "ADB (Android Debug Bridge) is not installed or not in PATH"
        echo ""
        echo -e "${WHITE}Install ADB:${NC}"
        echo "  Ubuntu/Debian: sudo apt-get install android-tools-adb"
        echo "  macOS: brew install android-platform-tools"
        echo "  Windows: Download Android SDK Platform Tools"
        return 1
    fi
    
    print_success "ADB is available"
    
    # Check if device is connected
    local devices=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
    
    if [[ $devices -eq 0 ]]; then
        print_error "No Android devices connected"
        echo ""
        echo -e "${WHITE}To connect a device:${NC}"
        echo "  1. Enable Developer Options on your Android device"
        echo "  2. Enable USB Debugging in Developer Options"
        echo "  3. Connect device via USB"
        echo "  4. Accept the debugging prompt on your device"
        echo "  5. Run: adb devices"
        return 1
    elif [[ $devices -eq 1 ]]; then
        local device_info=$(adb devices | grep -v "List of devices" | grep -v "^$")
        print_success "Device connected: $device_info"
    else
        print_warning "Multiple devices connected ($devices devices)"
        echo -e "${WHITE}Connected devices:${NC}"
        adb devices | grep -v "List of devices" | grep -v "^$" | sed 's/^/  /'
        echo ""
        echo -e "${WHITE}Note:${NC} Will install to all connected devices"
    fi
    
    return 0
}

# Function to install a single APK
install_apk() {
    local apk_file="$1"
    local filename=$(basename "$apk_file")
    
    print_installing "Installing: $filename"
    
    # Get file size for display
    local file_size=$(du -h "$apk_file" | cut -f1)
    echo -e "  ${CYAN}File:${NC} $filename"
    echo -e "  ${CYAN}Size:${NC} $file_size"
    
    # Try to install
    if adb install "$apk_file" 2>/dev/null; then
        print_success "Installed successfully"
        return 0
    else
        # Try with -r flag (reinstall) in case app already exists
        print_info "App might already exist, trying to reinstall..."
        if adb install -r "$apk_file" 2>/dev/null; then
            print_success "Reinstalled successfully"
            return 0
        else
            print_error "Failed to install $filename"
            echo -e "  ${RED}Common issues:${NC}"
            echo -e "    • App requires newer Android version"
            echo -e "    • App conflicts with existing installation"
            echo -e "    • Device storage full"
            echo -e "    • APK file corrupted"
            return 1
        fi
    fi
}

# Main function
main() {
    print_header
    
    print_info "Installing APKs from offline collection to Android device"
    echo ""
    
    # Check if data directory exists
    if [[ ! -d "$DATA_DIR" ]]; then
        print_error "Data directory not found: $DATA_DIR"
        echo ""
        print_info "Run ./download.sh first to download APK files"
        exit 1
    fi
    
    # Find all APK files
    APK_FILES=($(find "$DATA_DIR" -name "*.apk" -type f | sort))
    
    if [[ ${#APK_FILES[@]} -eq 0 ]]; then
        print_error "No APK files found in: $DATA_DIR"
        echo ""
        print_info "Run ./download.sh first to download APK files"
        exit 1
    fi
    
    # Show found APKs
    echo -e "${WHITE}${BOLD}📱 Found APK files:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    
    local total_size=0
    for apk_file in "${APK_FILES[@]}"; do
        local filename=$(basename "$apk_file")
        local file_size=$(du -h "$apk_file" | cut -f1)
        local file_size_bytes=$(du -b "$apk_file" | cut -f1)
        total_size=$((total_size + file_size_bytes))
        echo -e "${CYAN}│${NC} ${WHITE}$filename${NC} ${BLUE}($file_size)${NC}"
    done
    
    local total_size_human=$(echo $total_size | awk '{
        if ($1 > 1024*1024*1024) printf "%.1fGB\n", $1/1024/1024/1024
        else if ($1 > 1024*1024) printf "%.1fMB\n", $1/1024/1024
        else if ($1 > 1024) printf "%.1fKB\n", $1/1024
        else printf "%dB\n", $1
    }')
    
    echo -e "${CYAN}│${NC} ${YELLOW}Total: ${#APK_FILES[@]} APKs (${total_size_human})${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Check ADB and device connection
    print_info "Checking ADB and device connection..."
    if ! check_adb; then
        exit 1
    fi
    echo ""
    
    print_info "Installing all ${#APK_FILES[@]} APKs to connected device(s)..."
    echo ""
    
    # Install all APKs
    echo -e "${WHITE}${BOLD}🚀 Starting installation...${NC}"
    echo ""
    
    local installed=0
    local failed=0
    local start_time=$(date +%s)
    
    # Temporarily disable exit on error for the install loop
    set +e
    
    for apk_file in "${APK_FILES[@]}"; do
        if install_apk "$apk_file"; then
            ((installed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    # Re-enable exit on error
    set -e
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Final summary
    echo -e "${WHITE}${BOLD}📊 Installation Summary:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}✅ Installed:${NC} $installed APKs"
    if [[ $failed -gt 0 ]]; then
        echo -e "${CYAN}│${NC} ${RED}❌ Failed:${NC}    $failed APKs"
    fi
    echo -e "${CYAN}│${NC} ${BLUE}⏱️  Duration:${NC}  ${duration}s"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    
    echo ""
    if [[ $failed -gt 0 ]]; then
        print_warning "Some installations failed. Check the logs above for details."
        print_info "You can re-run this script to retry failed installations"
        exit 1
    else
        print_success "All APKs installed successfully!"
        echo ""
        print_info "Apps are now available on your Android device"
        print_info "Some apps may require additional setup or permissions"
    fi
}

# Handle script arguments
case "${1:-}" in
    -h|--help)
        print_header
        echo -e "${WHITE}${BOLD}USAGE:${NC}"
        echo -e "  $0                    ${WHITE}Install all APKs in data/ directory${NC}"
        echo ""
        echo -e "${WHITE}${BOLD}REQUIREMENTS:${NC}"
        echo -e "  • ADB (Android Debug Bridge) installed"
        echo -e "  • Android device connected via USB"
        echo -e "  • USB Debugging enabled on device"
        echo -e "  • APK files downloaded (run ./download.sh first)"
        echo ""
        echo -e "${WHITE}${BOLD}NOTES:${NC}"
        echo -e "  • Script will install to all connected devices"
        echo -e "  • Existing apps will be updated/reinstalled"
        echo -e "  • Failed installations can be retried"
        echo ""
        exit 0
        ;;
    "")
        # No arguments, run main function
        main "$@"
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac