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

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                  Copy ZIM to Android Device                    ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          Transfer ZIM files to Kiwix app directory            ${NC}${CYAN}║${NC}"
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

print_copying() {
    echo -e "${PURPLE}📱 $1${NC}"
}

show_help() {
    print_header
    echo -e "${WHITE}${BOLD}USAGE:${NC}"
    echo -e "  $0 <zim_file_path>     ${WHITE}Copy ZIM file to Android device${NC}"
    echo -e "  $0 -h|--help           ${WHITE}Show this help message${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}DESCRIPTION:${NC}"
    echo -e "  Copies ZIM files to the Kiwix Android app directory using ADB."
    echo -e "  The file will be placed in /sdcard/Android/media/org.kiwix.kiwixmobile/"
    echo -e "  where the Kiwix app can automatically detect and use it."
    echo ""
    echo -e "${WHITE}${BOLD}REQUIREMENTS:${NC}"
    echo -e "  • ADB (Android Debug Bridge) installed and in PATH"
    echo -e "  • Android device connected via USB with USB debugging enabled"
    echo -e "  • Kiwix app installed on the device (org.kiwix.kiwixmobile)"
    echo ""
    echo -e "${WHITE}${BOLD}EXAMPLES:${NC}"
    echo -e "  $0 data/wikipedia_en_all_novid.zim"
    echo -e "  $0 /path/to/my/archive.zim"
    echo -e "  $0 ../downloads/stackoverflow.com_en_all.zim"
    echo ""
    echo -e "${WHITE}${BOLD}NOTES:${NC}"
    echo -e "  • ZIM files can be large - transfer may take several minutes"
    echo -e "  • After transfer, swipe down in Kiwix Library to refresh file list"
    echo -e "  • Works with both Google Play and standalone Kiwix versions"
    echo -e "  • Files are copied to public app directory for easy management"
    echo ""
}

check_adb() {
    if ! command -v adb >/dev/null 2>&1; then
        print_error "ADB (Android Debug Bridge) is not installed or not in PATH"
        echo ""
        echo -e "${WHITE}Install ADB:${NC}"
        echo "  Ubuntu/Debian: sudo apt-get install android-tools-adb"
        echo "  macOS: brew install android-platform-tools"
        echo "  Windows: Download Android SDK Platform Tools"
        echo ""
        echo -e "${WHITE}Or use the offline installer:${NC}"
        echo "  cd ../apps/linux/deb && ./install.sh adb"
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
        echo -e "${WHITE}Note:${NC} Will copy to all connected devices"
    fi
    
    return 0
}

copy_zim_file() {
    local zim_file="$1"
    local filename=$(basename "$zim_file")
    local android_path="/sdcard/Android/media/org.kiwix.kiwixmobile"
    
    print_copying "Copying: $filename"
    
    # Get file size for display
    local file_size=$(du -h "$zim_file" | cut -f1)
    echo -e "  ${CYAN}Source:${NC} $zim_file"
    echo -e "  ${CYAN}Size:${NC} $file_size"
    echo -e "  ${CYAN}Destination:${NC} $android_path/$filename"
    echo ""
    
    # Create the directory on Android device if it doesn't exist
    print_info "Creating Kiwix directory on device..."
    if ! adb shell mkdir -p "$android_path" 2>/dev/null; then
        print_warning "Could not create directory (may already exist)"
    fi
    
    # Copy the file
    print_info "Transferring file (this may take several minutes for large files)..."
    if adb push "$zim_file" "$android_path/$filename"; then
        print_success "Transfer completed successfully"
        echo ""
        
        # Verify the file exists on device
        print_info "Verifying file on device..."
        if adb shell ls -lh "$android_path/$filename" 2>/dev/null; then
            print_success "File verified on device"
        else
            print_warning "Could not verify file on device (but transfer reported success)"
        fi
        
        echo ""
        print_info "Next steps:"
        echo -e "  ${WHITE}1.${NC} Open Kiwix app on your Android device"
        echo -e "  ${WHITE}2.${NC} Go to Library section"
        echo -e "  ${WHITE}3.${NC} Swipe down to refresh and detect new ZIM files"
        echo -e "  ${WHITE}4.${NC} Your ZIM file should appear in the local library"
        
        return 0
    else
        print_error "Failed to transfer $filename"
        echo ""
        echo -e "${RED}Common issues:${NC}"
        echo -e "    • Device storage full"
        echo -e "    • USB connection lost during transfer"
        echo -e "    • Permission denied (try different USB connection mode)"
        echo -e "    • Kiwix app not installed (install org.kiwix.kiwixmobile)"
        return 1
    fi
}

main() {
    local zim_file="$1"
    
    print_header
    
    print_info "Copying ZIM file to Android Kiwix app directory"
    echo ""
    
    # Validate ZIM file path
    if [[ ! -f "$zim_file" ]]; then
        print_error "ZIM file not found: $zim_file"
        echo ""
        print_info "Make sure the file path is correct and the file exists"
        exit 1
    fi
    
    # Check if it's actually a ZIM file
    if [[ ! "$zim_file" =~ \.zim$ ]]; then
        print_warning "File doesn't have .zim extension: $(basename "$zim_file")"
        echo -e "${WHITE}Continue anyway? (y/N):${NC} "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled"
            exit 0
        fi
    fi
    
    # Check ADB and device connection
    print_info "Checking ADB and device connection..."
    if ! check_adb; then
        exit 1
    fi
    echo ""
    
    # Copy the file
    if copy_zim_file "$zim_file"; then
        echo ""
        print_success "ZIM file successfully copied to Android device!"
    else
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        print_error "No ZIM file specified"
        echo ""
        echo -e "${WHITE}Usage:${NC} $0 <zim_file_path>"
        echo -e "${WHITE}Help:${NC}  $0 --help"
        exit 1
        ;;
    *)
        main "$1"
        ;;
esac