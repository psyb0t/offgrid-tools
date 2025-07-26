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

# ZIM List - format: "ZIM Name|URL|Description"
ZIMS=(
    "FreeCodeCamp|https://download.kiwix.org/zim/freecodecamp/freecodecamp_en_all_2025-07.zim|Learn to code with tutorials and interactive lessons"
    "Termux Documentation|https://download.kiwix.org/zim/other/termux_en_all_maxi_2022-12.zim|Complete Android terminal emulator documentation"
    "Military Medicine|https://download.kiwix.org/zim/zimit/fas-military-medicine_en_2025-06.zim|Emergency medical procedures and combat medicine"
    "C++ Documentation|https://download.kiwix.org/zim/devdocs/devdocs_en_cpp_2025-07.zim|Complete C++ language reference and documentation"
    "Go Documentation|https://download.kiwix.org/zim/devdocs/devdocs_en_go_2025-07.zim|Go programming language documentation"
    "Docker Documentation|https://download.kiwix.org/zim/devdocs/devdocs_en_docker_2025-07.zim|Docker containerization platform documentation"
    "JavaScript Documentation|https://download.kiwix.org/zim/devdocs/devdocs_en_javascript_2025-07.zim|JavaScript language reference and APIs"
    "C Documentation|https://download.kiwix.org/zim/devdocs/devdocs_en_c_2025-07.zim|C programming language documentation"
    "CSS Documentation|https://download.kiwix.org/zim/devdocs/devdocs_en_css_2025-07.zim|CSS styling and layout documentation"
    "HTML Documentation|https://download.kiwix.org/zim/devdocs/devdocs_en_html_2025-07.zim|HTML markup language documentation"
)

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                     ZIM Archive Downloader                     ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}           Download offline content archives for Kiwix           ${NC}${CYAN}║${NC}"
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
    echo -e "${PURPLE}📚 $1${NC}"
}

# Function to extract filename from URL
get_filename() {
    local url="$1"
    local filename
    
    # Extract filename from URL
    filename=$(basename "$url")
    
    # If it doesn't look like a ZIM file, generate a fallback name
    if [[ ! "$filename" =~ \.zim$ ]]; then
        filename="archive_$(date +%s).zim"
    fi
    
    echo "$filename"
}

# Function to download a single ZIM
download_zim() {
    local zim_name="$1"
    local url="$2"
    local description="$3"
    local filename
    
    print_downloading "Downloading: $zim_name"
    echo -e "  ${CYAN}Description:${NC} $description"
    echo -e "  ${CYAN}URL:${NC} $url"
    
    # Get filename
    filename=$(get_filename "$url")
    local filepath="$DATA_DIR/$filename"
    
    echo -e "  ${CYAN}File:${NC} $filename"
    
    # Check if file already exists
    if [[ -f "$filepath" ]]; then
        local existing_size=$(du -h "$filepath" | cut -f1)
        print_warning "File already exists ($existing_size), skipping"
        return 2  # Return 2 to indicate "skipped"
    fi
    
    # Create temp file for partial download
    local temp_filepath="${filepath}.tmp"
    
    # Download with progress and resume capability
    if curl -L --fail --progress-bar --continue-at - -o "$temp_filepath" "$url"; then
        # Move temp file to final location
        mv "$temp_filepath" "$filepath"
        
        local file_size=$(du -h "$filepath" | cut -f1)
        print_success "Downloaded successfully ($file_size)"
        
        return 0
    else
        print_error "Failed to download $zim_name"
        # Clean up partial/temp download
        [[ -f "$temp_filepath" ]] && rm -f "$temp_filepath"
        [[ -f "$filepath" ]] && rm -f "$filepath"
        return 1
    fi
}

# Main function
main() {
    print_header
    
    print_info "Essential offline content archives for survival and development"
    echo ""
    
    # Create data directory if it doesn't exist
    if [[ ! -d "$DATA_DIR" ]]; then
        print_info "Creating data directory: $DATA_DIR"
        mkdir -p "$DATA_DIR"
    fi
    
    # Clean up existing data directory option
    if [[ -d "$DATA_DIR" ]] && [[ "$(ls -A "$DATA_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}🗂️  Data directory contains existing files:${NC}"
        ls -lh "$DATA_DIR"/*.zim 2>/dev/null | sed 's/^/  /' || echo "  No ZIM files found"
        echo ""
        
        read -p "Clean up existing ZIM files before downloading? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleaning up existing ZIM files..."
            rm -f "$DATA_DIR"/*.zim "$DATA_DIR"/*.tmp
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
    
    
    echo ""
    
    echo -e "${WHITE}${BOLD}📋 ZIM Download List:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    
    local count=1
    for zim_entry in "${ZIMS[@]}"; do
        IFS='|' read -r zim_name url description <<< "$zim_entry"
        echo -e "${CYAN}│${NC} ${YELLOW}$count.${NC} ${WHITE}$zim_name${NC}"
        echo -e "${CYAN}│${NC}    ${description}"
        ((count++))
    done
    
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Download statistics
    local downloaded=0
    local failed=0
    local skipped=0
    
    # Download each ZIM
    echo -e "${WHITE}${BOLD}🚀 Starting downloads...${NC}"
    echo -e "${YELLOW}⚠️  Large files - this may take a while on slow connections${NC}"
    echo -e "${BLUE}ℹ️  Downloads can be resumed if interrupted (CTRL+C to stop)${NC}"
    echo ""
    
    # Temporarily disable exit on error for the download loop
    set +e
    
    for zim_entry in "${ZIMS[@]}"; do
        IFS='|' read -r zim_name url description <<< "$zim_entry"
        
        download_zim "$zim_name" "$url" "$description"
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
    echo -e "${CYAN}│${NC} ${GREEN}✅ Downloaded:${NC} $downloaded ZIMs"
    echo -e "${CYAN}│${NC} ${YELLOW}⏭️  Skipped:${NC}    $skipped ZIMs (already existed)"
    if [[ $failed -gt 0 ]]; then
        echo -e "${CYAN}│${NC} ${RED}❌ Failed:${NC}     $failed ZIMs"
    fi
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    
    if [[ -d "$DATA_DIR" ]] && [[ "$(ls -A "$DATA_DIR" 2>/dev/null)" ]]; then
        echo ""
        echo -e "${WHITE}${BOLD}📚 Downloaded ZIM archives:${NC}"
        ls -lh "$DATA_DIR"/*.zim 2>/dev/null | sed 's/^/  /' || echo "  No ZIM files found"
        
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
        print_success "All ZIM archives downloaded successfully!"
        echo ""
        print_info "Archives are ready to use with Kiwix server"
        print_info "Start the services with: docker-compose up"
        print_info "Access content at: http://localhost:8000"
        print_info "Files are saved in: $DATA_DIR"
    fi
}

# Run main function
main "$@"