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
    echo -e "${CYAN}║${WHITE}${BOLD}                   ISO Image Installer/Burner                   ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}            Create bootable USB drives from ISO files           ${NC}${CYAN}║${NC}"
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

print_critical() {
    echo -e "${RED}${BOLD}🚨 CRITICAL: $1${NC}"
}

# Function to list available ISOs
list_isos() {
    echo -e "${WHITE}${BOLD}💿 Available ISO files:${NC}"
    
    if [[ ! -d "$DATA_DIR" ]] || [[ ! "$(ls -A "$DATA_DIR"/*.iso "$DATA_DIR"/*.img 2>/dev/null)" ]]; then
        print_warning "No ISO files found in $DATA_DIR"
        echo "  Run ./download.sh first to download ISO images"
        return 1
    fi
    
    local count=1
    local iso_files=()
    
    # Collect all ISO/IMG files
    while IFS= read -r -d '' file; do
        iso_files+=("$file")
    done < <(find "$DATA_DIR" -name "*.iso" -o -name "*.img" -print0 2>/dev/null | sort -z)
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    for file in "${iso_files[@]}"; do
        local filename=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        echo -e "${CYAN}│${NC} ${YELLOW}$count.${NC} ${WHITE}$filename${NC} ${BLUE}($size)${NC}"
        ((count++))
    done
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    
    # Store files for selection
    printf '%s\n' "${iso_files[@]}"
}

# Function to list USB devices
list_usb_devices() {
    echo -e "${WHITE}${BOLD}🔌 Available USB devices:${NC}"
    
    if ! command -v lsblk >/dev/null 2>&1; then
        print_error "lsblk command not available - cannot detect USB devices"
        return 1
    fi
    
    # Find removable storage devices
    local usb_devices=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            usb_devices+=("$line")
        fi
    done < <(lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E "(usb|USB)" | grep -v "loop\|sr" || true)
    
    if [[ ${#usb_devices[@]} -eq 0 ]]; then
        print_warning "No USB storage devices detected"
        echo "  Make sure your USB drive is connected and recognized by the system"
        echo "  You can check with: lsblk"
        return 1
    fi
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}DEVICE     SIZE    MODEL${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    for device in "${usb_devices[@]}"; do
        echo -e "${CYAN}│${NC} $device"
    done
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    
    return 0
}

# Function to verify device selection
verify_device() {
    local device="$1"
    
    # Ensure device path starts with /dev/
    if [[ ! "$device" =~ ^/dev/ ]]; then
        device="/dev/$device"
    fi
    
    # Check if device exists
    if [[ ! -b "$device" ]]; then
        print_error "Device $device does not exist or is not a block device"
        return 1
    fi
    
    # Check if device is mounted
    if mount | grep -q "^$device"; then
        print_critical "Device $device is currently mounted!"
        echo "  Mounted partitions:"
        mount | grep "^$device" | sed 's/^/    /'
        echo ""
        print_warning "Unmount all partitions before proceeding"
        echo "  Example: sudo umount ${device}1 ${device}2"
        return 1
    fi
    
    # Get device info
    local device_size=$(lsblk -b -d -o SIZE "$device" 2>/dev/null | tail -n1)
    local device_model=$(lsblk -d -o MODEL "$device" 2>/dev/null | tail -n1 | xargs)
    
    echo -e "${BLUE}Selected device:${NC}"
    echo -e "  Device: ${WHITE}$device${NC}"
    echo -e "  Model:  ${WHITE}$device_model${NC}"
    echo -e "  Size:   ${WHITE}$(numfmt --to=iec-i --suffix=B $device_size)${NC}"
    
    return 0
}

# Function to burn ISO to USB
burn_iso() {
    local iso_file="$1"
    local device="$2"
    
    local iso_name=$(basename "$iso_file")
    local iso_size=$(stat -c%s "$iso_file")
    local device_size=$(lsblk -b -d -o SIZE "$device" 2>/dev/null | tail -n1)
    
    print_info "Preparing to burn ISO to USB..."
    echo -e "  ISO file: ${WHITE}$iso_name${NC}"
    echo -e "  ISO size: ${WHITE}$(numfmt --to=iec-i --suffix=B $iso_size)${NC}"
    echo -e "  Device:   ${WHITE}$device${NC}"
    echo -e "  Device size: ${WHITE}$(numfmt --to=iec-i --suffix=B $device_size)${NC}"
    
    # Check if ISO fits on device
    if [[ $iso_size -gt $device_size ]]; then
        print_error "ISO file ($iso_size bytes) is larger than device ($device_size bytes)"
        return 1
    fi
    
    echo ""
    print_critical "THIS WILL COMPLETELY ERASE ALL DATA ON $device"
    print_critical "This action cannot be undone!"
    echo ""
    
    read -p "Are you absolutely sure you want to continue? Type 'YES' to proceed: " -r
    if [[ "$REPLY" != "YES" ]]; then
        print_info "Operation cancelled by user"
        return 1
    fi
    
    echo ""
    print_info "Starting ISO burn process..."
    print_warning "Do not disconnect the USB drive during this process!"
    
    # Use dd to write ISO to device
    if command -v pv >/dev/null 2>&1; then
        # Use pv for progress if available
        print_info "Using pv for progress monitoring..."
        if pv "$iso_file" | sudo dd of="$device" bs=4M oflag=sync status=none; then
            print_success "ISO burned successfully with progress monitoring"
        else
            print_error "Failed to burn ISO using pv"
            return 1
        fi
    else
        # Fallback to dd with progress
        print_info "Using dd for burning (no progress bar available)..."
        print_info "Install 'pv' for progress monitoring: sudo apt-get install pv"
        
        if sudo dd if="$iso_file" of="$device" bs=4M status=progress oflag=sync; then
            print_success "ISO burned successfully"
        else
            print_error "Failed to burn ISO using dd"
            return 1
        fi
    fi
    
    # Sync to ensure all data is written
    print_info "Syncing data to device..."
    sudo sync
    
    print_success "USB drive creation completed!"
    echo ""
    print_info "Your bootable USB drive is ready"
    print_info "You can now safely remove the USB drive"
}

# Function for interactive mode
interactive_mode() {
    print_header
    print_info "Interactive USB bootable drive creation"
    echo ""
    
    # List available ISOs
    local iso_files
    mapfile -t iso_files < <(list_isos)
    if [[ ${#iso_files[@]} -eq 0 ]]; then
        exit 1
    fi
    
    echo ""
    
    # Select ISO file
    while true; do
        read -p "Select ISO file (1-${#iso_files[@]}): " -r iso_choice
        
        if [[ "$iso_choice" =~ ^[0-9]+$ ]] && [[ $iso_choice -ge 1 ]] && [[ $iso_choice -le ${#iso_files[@]} ]]; then
            selected_iso="${iso_files[$((iso_choice - 1))]}"
            print_success "Selected: $(basename "$selected_iso")"
            break
        else
            print_error "Invalid selection. Please enter a number between 1 and ${#iso_files[@]}"
        fi
    done
    
    echo ""
    
    # List USB devices
    if ! list_usb_devices; then
        exit 1
    fi
    
    echo ""
    
    # Select USB device
    while true; do
        read -p "Enter USB device (e.g., sdb, sdc): " -r device_choice
        
        if verify_device "$device_choice"; then
            # Ensure device path format
            if [[ ! "$device_choice" =~ ^/dev/ ]]; then
                device_choice="/dev/$device_choice"
            fi
            break
        else
            echo ""
            print_error "Invalid device or device not ready. Please try again."
            echo ""
        fi
    done
    
    echo ""
    
    # Burn ISO
    if burn_iso "$selected_iso" "$device_choice"; then
        print_success "Bootable USB creation completed successfully!"
    else
        print_error "Failed to create bootable USB"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create bootable USB drives from downloaded ISO files"
    echo ""
    echo "Options:"
    echo "  -i, --interactive    Interactive mode (default)"
    echo "  -l, --list-isos      List available ISO files"
    echo "  -u, --list-usb       List available USB devices"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Interactive mode"
    echo "  $0 -l               # List available ISOs"
    echo "  $0 -u               # List USB devices"
    echo ""
    echo "Requirements:"
    echo "  - Root/sudo access for writing to USB devices"
    echo "  - USB device connected and recognized"
    echo "  - ISO files downloaded in data/ directory"
}

# Main function
main() {
    # Check if running as root for device operations
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root - be extra careful with device selection!"
    fi
    
    # Check dependencies
    if ! command -v dd >/dev/null 2>&1; then
        print_error "dd command not available - cannot write to USB devices"
        exit 1
    fi
    
    if ! command -v lsblk >/dev/null 2>&1; then
        print_warning "lsblk not available - device detection may be limited"
    fi
    
    # Parse command line arguments
    case "${1:-}" in
        -l|--list-isos)
            list_isos >/dev/null
            ;;
        -u|--list-usb)
            list_usb_devices
            ;;
        -h|--help)
            show_usage
            ;;
        -i|--interactive|"")
            interactive_mode
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"