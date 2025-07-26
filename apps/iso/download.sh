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

# ISO List - format: "ISO Name|URL|Description"
ISOS=(
    "Ventoy Live CD|https://sourceforge.net/projects/ventoy/files/v1.1.05/ventoy-1.1.05-livecd.iso|Multi-boot USB creator and manager"
    "Xubuntu 24.04.2|https://mirror.us.leaseweb.net/ubuntu-cdimage/xubuntu/releases/24.04/release/xubuntu-24.04.2-desktop-amd64.iso|Lightweight Ubuntu with XFCE desktop"
    "Lubuntu 24.04.2|https://cdimage.ubuntu.com/lubuntu/releases/noble/release/lubuntu-24.04.2-desktop-amd64.iso|Ultra-lightweight Ubuntu with LXQt desktop"
    "Kali Linux 2025.2|https://ftp.riken.jp/Linux/kali-images/current/kali-linux-2025.2-installer-amd64.iso|Security and penetration testing distro"
    "Tiny11 23H2|https://archive.org/download/tiny-11-NTDEV/tiny11%2023H2%20x64.iso|Stripped-down Windows 11 build"
    "TinyCore Linux CorePlus|http://tinycorelinux.net/16.x/x86/release/CorePlus-current.iso|Extremely minimal modular Linux that runs in RAM - installation image with multiple desktops"
)

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                     ISO Image Downloader                      ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}           Download bootable OS images for offline use          ${NC}${CYAN}║${NC}"
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

print_downloading() {
    echo -e "${PURPLE}💿 $1${NC}"
}

# Function to extract filename from URL
get_filename() {
    local url="$1"
    local filename
    
    # Extract filename from URL, handle URL encoding
    filename=$(basename "$url" | sed 's/%20/ /g')
    
    # If it doesn't look like an ISO file, generate a fallback name
    if [[ ! "$filename" =~ \.(iso|img)$ ]]; then
        filename="image_$(date +%s).iso"
    fi
    
    echo "$filename"
}

# Function to format file size
format_size() {
    local size=$1
    if [[ $size -gt 1073741824 ]]; then  # > 1GB
        echo "$(( size / 1073741824 ))GB"
    elif [[ $size -gt 1048576 ]]; then   # > 1MB
        echo "$(( size / 1048576 ))MB"
    else
        echo "$(( size / 1024 ))KB"
    fi
}

# Function to download a single ISO
download_iso() {
    local iso_name="$1"
    local url="$2"
    local description="$3"
    local filename
    
    print_downloading "Downloading: $iso_name"
    echo -e "  ${CYAN}Description:${NC} $description"
    echo -e "  ${CYAN}URL:${NC} $url"
    
    # Get filename
    filename=$(get_filename "$url")
    local filepath="$DATA_DIR/$filename"
    
    echo -e "  ${CYAN}File:${NC} $filename"
    
    # Check if file already exists
    if [[ -f "$filepath" ]]; then
        local existing_size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
        local existing_size_fmt=$(format_size $existing_size)
        print_warning "File already exists ($existing_size_fmt), skipping"
        return 2  # Return 2 to indicate "skipped"
    fi
    
    # Create temp file for partial download
    local temp_filepath="${filepath}.tmp"
    
    # Download with progress and resume capability
    if curl -L --fail --progress-bar --continue-at - -o "$temp_filepath" "$url"; then
        # Move temp file to final location
        mv "$temp_filepath" "$filepath"
        
        local file_size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
        local file_size_fmt=$(format_size $file_size)
        print_success "Downloaded successfully ($file_size_fmt)"
        
        # Basic file verification
        if file "$filepath" | grep -E -q "(ISO 9660|UDF filesystem|DOS/MBR boot sector)"; then
            echo -e "  ${GREEN}✓${NC} Bootable image verified"
        else
            print_warning "Downloaded file might not be a valid bootable image"
        fi
        
        return 0
    else
        print_error "Failed to download $iso_name"
        # Clean up partial/temp download
        [[ -f "$temp_filepath" ]] && rm -f "$temp_filepath"
        [[ -f "$filepath" ]] && rm -f "$filepath"
        return 1
    fi
}

# Function to show disk space requirements
check_disk_space() {
    local required_space=0
    local available_space
    
    # Estimate space needed (rough estimates in bytes)
    declare -A iso_sizes=(
        ["Ventoy Live CD"]=400000000      # ~400MB
        ["Xubuntu 24.04.2"]=3500000000   # ~3.5GB
        ["Lubuntu 24.04.2"]=3200000000   # ~3.2GB  
        ["Kali Linux 2025.2"]=4000000000 # ~4GB
        ["Tiny11 23H2"]=5000000000       # ~5GB
        ["TinyCore Linux CorePlus"]=110000000      # ~106MB
    )
    
    print_info "Estimated storage requirements:"
    for iso_entry in "${ISOS[@]}"; do
        IFS='|' read -r iso_name url description <<< "$iso_entry"
        local size=${iso_sizes[$iso_name]}
        if [[ -n "$size" ]]; then
            echo -e "  • ${YELLOW}$iso_name${NC}: $(format_size $size)"
            required_space=$((required_space + size))
        fi
    done
    
    echo -e "  ${BOLD}Total estimated: $(format_size $required_space)${NC}"
    
    # Check available space in data directory
    available_space=$(df "$DATA_DIR" | awk 'NR==2 {print $4*1024}')
    echo -e "  ${BOLD}Available space: $(format_size $available_space)${NC}"
    
    if [[ $available_space -lt $required_space ]]; then
        print_warning "You may not have enough disk space for all downloads"
        echo -e "  ${YELLOW}Consider freeing up space or downloading selectively${NC}"
    else
        print_success "Sufficient disk space available"
    fi
    echo ""
}

# Main function
main() {
    print_header
    
    print_info "Essential bootable OS images for offline/survival scenarios"
    echo ""
    
    # Create data directory if it doesn't exist
    if [[ ! -d "$DATA_DIR" ]]; then
        print_info "Creating data directory: $DATA_DIR"
        mkdir -p "$DATA_DIR"
    fi
    
    # Clean up existing data directory option
    if [[ -d "$DATA_DIR" ]] && [[ "$(ls -A "$DATA_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}🗂️  Data directory contains existing files:${NC}"
        ls -lh "$DATA_DIR"/*.iso 2>/dev/null | sed 's/^/  /' || echo "  No ISO files found"
        echo ""
        
        read -p "Clean up existing ISOs before downloading? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleaning up existing ISO files..."
            rm -f "$DATA_DIR"/*.iso "$DATA_DIR"/*.img "$DATA_DIR"/*.tmp
            print_success "Cleanup completed"
        fi
        echo ""
    fi
    
    # Check dependencies
    print_info "Checking dependencies..."
    
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl is required but not installed"
        echo "  Install with: sudo apt-get install curl"
        exit 1
    fi
    print_success "curl is available"
    
    if ! command -v file >/dev/null 2>&1; then
        print_warning "file command not available - ISO verification will be skipped"
    else
        print_success "file command is available"
    fi
    
    echo ""
    check_disk_space
    
    echo -e "${WHITE}${BOLD}📋 ISO Download List:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    
    local count=1
    for iso_entry in "${ISOS[@]}"; do
        IFS='|' read -r iso_name url description <<< "$iso_entry"
        echo -e "${CYAN}│${NC} ${YELLOW}$count.${NC} ${WHITE}$iso_name${NC}"
        echo -e "${CYAN}│${NC}    ${description}"
        ((count++))
    done
    
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Download statistics
    local downloaded=0
    local failed=0
    local skipped=0
    
    # Download each ISO
    echo -e "${WHITE}${BOLD}🚀 Starting downloads...${NC}"
    echo -e "${YELLOW}⚠️  Large files - this may take a while on slow connections${NC}"
    echo -e "${BLUE}ℹ️  Downloads can be resumed if interrupted (CTRL+C to stop)${NC}"
    echo ""
    
    # Temporarily disable exit on error for the download loop
    set +e
    
    for iso_entry in "${ISOS[@]}"; do
        IFS='|' read -r iso_name url description <<< "$iso_entry"
        
        download_iso "$iso_name" "$url" "$description"
        download_result=$?
        
        if [[ $download_result -eq 0 ]]; then
            ((downloaded++))
        elif [[ $download_result -eq 2 ]]; then
            ((skipped++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    # Re-enable exit on error
    set -e
    
    # Final summary
    echo -e "${WHITE}${BOLD}📊 Download Summary:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}✅ Downloaded:${NC} $downloaded ISOs"
    echo -e "${CYAN}│${NC} ${YELLOW}⏭️  Skipped:${NC}    $skipped ISOs (already existed)"
    if [[ $failed -gt 0 ]]; then
        echo -e "${CYAN}│${NC} ${RED}❌ Failed:${NC}     $failed ISOs"
    fi
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    
    if [[ -d "$DATA_DIR" ]] && [[ "$(ls -A "$DATA_DIR" 2>/dev/null)" ]]; then
        echo ""
        echo -e "${WHITE}${BOLD}💿 Downloaded ISOs:${NC}"
        ls -lh "$DATA_DIR"/*.iso "$DATA_DIR"/*.img 2>/dev/null | sed 's/^/  /' || echo "  No image files found"
        
        echo ""
        echo -e "${BLUE}📦 Total size:${NC}"
        du -sh "$DATA_DIR" | sed 's/^/  /'
    fi
    
    echo ""
    if [[ $failed -gt 0 ]]; then
        print_warning "Some downloads failed. Check the logs above for details."
        print_info "You can re-run this script to retry failed downloads"
        exit 1
    else
        print_success "All ISOs downloaded successfully!"
        echo ""
        print_info "Create bootable USB with: dd if=<filename>.iso of=/dev/sdX bs=4M status=progress"
        print_info "Or use tools like Ventoy, Rufus, or Etcher"
        print_info "Files are saved in: $DATA_DIR"
        echo ""
        print_warning "CAUTION: Verify USB device path before using dd command!"
    fi
}

# Run main function
main "$@"