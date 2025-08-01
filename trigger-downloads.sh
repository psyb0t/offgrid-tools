#!/bin/bash

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

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                    Offgrid Tools Downloader                    ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}              Trigger all download scripts at once              ${NC}${CYAN}║${NC}"
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

print_section() {
    echo -e "${PURPLE}${BOLD}🚀 $1${NC}"
}

# Function to run a download script
run_download() {
    local script_path="$1"
    local description="$2"
    local dir_path=$(dirname "$script_path")
    
    echo ""
    print_section "Starting: $description"
    echo -e "  ${CYAN}Script:${NC} $script_path"
    echo -e "  ${CYAN}Directory:${NC} $dir_path"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        print_warning "Script not executable, making it executable: $script_path"
        chmod +x "$script_path"
    fi
    
    # Change to script directory and run it
    if (cd "$dir_path" && ./$(basename "$script_path")); then
        print_success "$description completed successfully"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Main function
main() {
    print_header
    
    print_info "This script will run all available download scripts in sequence"
    print_warning "This may take a very long time and use significant disk space"
    print_warning "Make sure you have sufficient internet bandwidth and storage"
    echo ""
    
    # List what will be downloaded
    echo -e "${WHITE}${BOLD}📋 Download scripts that will be executed:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}1.${NC} ${WHITE}Docker Images${NC} - Container images for offline use"
    echo -e "${CYAN}│${NC} ${YELLOW}2.${NC} ${WHITE}Android APKs${NC} - Essential mobile apps"
    echo -e "${CYAN}│${NC} ${YELLOW}3.${NC} ${WHITE}ISO Images${NC} - Bootable operating systems"
    echo -e "${CYAN}│${NC} ${YELLOW}4.${NC} ${WHITE}ZIM Archives${NC} - Offline content for Kiwix"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Download cancelled by user"
        exit 0
    fi
    
    echo ""
    print_info "Starting download sequence..."
    
    # Track results
    local total_scripts=4
    local successful=0
    local failed=0
    local failed_scripts=()
    
    # Define download scripts in order
    local downloads=(
        "$SCRIPT_DIR/save-docker-images.sh|Docker Images"
        "$SCRIPT_DIR/apps/android/apk/download.sh|Android APKs"
        "$SCRIPT_DIR/apps/iso/download.sh|ISO Images"
        "$SCRIPT_DIR/zim/download.sh|ZIM Archives"
    )
    
    # Run each download script
    for download_entry in "${downloads[@]}"; do
        IFS='|' read -r script_path description <<< "$download_entry"
        
        if run_download "$script_path" "$description"; then
            ((successful++))
        else
            ((failed++))
            failed_scripts+=("$description")
        fi
        
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    done
    
    # Final summary
    echo ""
    echo -e "${WHITE}${BOLD}📊 Download Summary:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}✅ Successful:${NC} $successful/$total_scripts scripts"
    if [[ $failed -gt 0 ]]; then
        echo -e "${CYAN}│${NC} ${RED}❌ Failed:${NC}     $failed/$total_scripts scripts"
    fi
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    
    if [[ $failed -gt 0 ]]; then
        echo ""
        print_warning "Failed downloads:"
        for failed_script in "${failed_scripts[@]}"; do
            echo -e "  • ${RED}$failed_script${NC}"
        done
        echo ""
        print_info "You can run individual scripts manually to retry failed downloads"
        exit 1
    else
        echo ""
        print_success "All downloads completed successfully!"
        echo ""
        print_info "Your offgrid toolkit is now ready for offline use"
        print_info "Start the services with: docker-compose up"
    fi
}

# Run main function
main "$@"