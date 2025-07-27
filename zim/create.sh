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

# Default values
DEFAULT_OUTPUT_DIR="./zim/data"
DEFAULT_WORKERS=10

# Recommended websites to archive
RECOMMENDED_SITES=(
    "https://www.sigidwiki.com/|sigidwiki|Signal identification wiki for radio frequency analysis"
    "https://www.hamuniverse.com/|hamuniverse|Ham radio resources and technical information"
    "https://learnxinyminutes.com/|learnxinyminutes|Quick programming language tutorials and cheat sheets"
    "https://trueprepper.com/|trueprepper|Survival and preparedness guides and resources"
    "https://readystate.cc/|readystate|Emergency preparedness and disaster response information"
    "https://www.survivopedia.com/|survivopedia|Survival skills and preparedness knowledge base"
    "https://wiki.gnuradio.org/|gnuradio-wiki|GNU Radio documentation and tutorials"
    "https://www.rtl-sdr.com/|rtl-sdr|RTL-SDR news, tutorials and projects"
)

# Function to print colored output
print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                        ZIM Creator                            ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}              Create offline archives with Zimit               ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_usage() {
    echo -e "${WHITE}${BOLD}USAGE:${NC}"
    echo -e "  $0 ${YELLOW}<URL>${NC} ${BLUE}<ZIM_NAME>${NC} [${GREEN}<OUTPUT_DIR>${NC}] [${PURPLE}<WORKERS>${NC}]"
    echo -e "  $0 ${CYAN}recommended${NC} [${GREEN}<OUTPUT_DIR>${NC}] [${PURPLE}<WORKERS>${NC}]"
    echo ""
    echo -e "${WHITE}${BOLD}ARGUMENTS:${NC}"
    echo -e "  ${YELLOW}URL${NC}         ${WHITE}Website URL to archive (required)${NC}"
    echo -e "              ${WHITE}Example: https://example.com${NC}"
    echo ""
    echo -e "  ${BLUE}ZIM_NAME${NC}    ${WHITE}Name for the ZIM file (required)${NC}"
    echo -e "              ${WHITE}Example: example.com${NC}"
    echo ""
    echo -e "  ${CYAN}recommended${NC} ${WHITE}Archive all recommended sites${NC}"
    echo ""
    echo -e "  ${GREEN}OUTPUT_DIR${NC}  ${WHITE}Local directory to save ZIM file (optional)${NC}"
    echo -e "              ${WHITE}Default: ${DEFAULT_OUTPUT_DIR}${NC}"
    echo ""
    echo -e "  ${PURPLE}WORKERS${NC}     ${WHITE}Number of concurrent workers (optional)${NC}"
    echo -e "              ${WHITE}Default: ${DEFAULT_WORKERS}${NC}"
    echo -e "              ${WHITE}Range: 1-100${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}EXAMPLES:${NC}"
    echo -e "  ${WHITE}Basic usage:${NC}"
    echo -e "    $0 https://example.com example.com"
    echo ""
    echo -e "  ${WHITE}Archive recommended sites:${NC}"
    echo -e "    $0 recommended"
    echo ""
    echo -e "  ${WHITE}Custom output directory:${NC}"
    echo -e "    $0 https://example.com example.com /home/user/archives"
    echo ""
    echo -e "  ${WHITE}Recommended with custom settings:${NC}"
    echo -e "    $0 recommended ./archives 25"
    echo ""
    echo -e "${WHITE}${BOLD}RECOMMENDED SITES:${NC}"
    for site in "${RECOMMENDED_SITES[@]}"; do
        IFS='|' read -r url name desc <<< "$site"
        echo -e "  • ${YELLOW}$url${NC} → ${BLUE}$name.zim${NC}"
        echo -e "    ${WHITE}$desc${NC}"
    done
    echo ""
    echo -e "${WHITE}${BOLD}OPTIONS:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}    ${WHITE}Show this help message${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}NOTES:${NC}"
    echo -e "  • The output directory will be created if it doesn't exist"
    echo -e "  • Higher worker counts can speed up crawling but use more resources"
    echo -e "  • The ZIM file will be saved as ${BLUE}<ZIM_NAME>.zim${NC}"
    echo -e "  • Requires Docker and the ${CYAN}ghcr.io/openzim/zimit${NC} image"
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

# Validate URL format
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        print_error "Invalid URL format. Must start with http:// or https://"
        return 1
    fi
    return 0
}

# Validate worker count
validate_workers() {
    local workers="$1"
    if [[ ! "$workers" =~ ^[0-9]+$ ]] || [[ "$workers" -lt 1 ]] || [[ "$workers" -gt 100 ]]; then
        print_error "Worker count must be a number between 1 and 100"
        return 1
    fi
    return 0
}

# Function to create a single ZIM file
create_single_zim() {
    local url="$1"
    local zim_name="$2"
    local output_dir="$3"
    local workers="$4"
    local site_num="$5"
    local total_sites="$6"
    
    echo ""
    if [[ -n "$site_num" && -n "$total_sites" ]]; then
        echo -e "${WHITE}${BOLD}🚀 [$site_num/$total_sites] Creating ZIM for: $url${NC}"
    else
        echo -e "${WHITE}${BOLD}🚀 Creating ZIM for: $url${NC}"
    fi
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}URL:${NC}      ${YELLOW}$url${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}ZIM Name:${NC} ${BLUE}$zim_name${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Workers:${NC}  ${PURPLE}$workers${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Run the Zimit container
    if docker run --rm \
        --network host \
        -v "$output_dir":/output \
        ghcr.io/openzim/zimit \
        zimit \
        --seeds "$url" \
        --name "$zim_name" \
        --workers "$workers"; then
        
        # Check if ZIM file starting with our name was created
        local latest_zim=$(find "$output_dir" -name "${zim_name}*.zim" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)
        
        if [[ -n "$latest_zim" && -f "$latest_zim" ]]; then
            local file_size=$(du -h "$latest_zim" | cut -f1)
            local file_name=$(basename "$latest_zim")
            echo -e "${GREEN}${BOLD}✅ SUCCESS: $zim_name${NC}"
            echo -e "${WHITE}File:${NC} ${GREEN}$file_name${NC} ${WHITE}(${BLUE}$file_size${NC}${WHITE})${NC}"
            return 0
        else
            print_error "No ZIM file starting with '$zim_name' was created"
            return 1
        fi
    else
        print_error "Failed to create ZIM file for $url"
        return 1
    fi
}

# Function to archive all recommended sites
archive_recommended() {
    local output_dir="$1"
    local workers="$2"
    
    echo -e "${WHITE}${BOLD}📋 Archiving ${#RECOMMENDED_SITES[@]} recommended sites...${NC}"
    echo ""
    
    local success_count=0
    local failed_count=0
    local failed_sites=()
    
    for i in "${!RECOMMENDED_SITES[@]}"; do
        local site="${RECOMMENDED_SITES[$i]}"
        IFS='|' read -r url name desc <<< "$site"
        
        if create_single_zim "$url" "$name" "$output_dir" "$workers" "$((i+1))" "${#RECOMMENDED_SITES[@]}"; then
            ((success_count++))
        else
            ((failed_count++))
            failed_sites+=("$name ($url)")
        fi
    done
    
    echo ""
    echo -e "${WHITE}${BOLD}📊 Recommended Sites Summary:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Total sites:${NC}     ${BLUE}${#RECOMMENDED_SITES[@]}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Successful:${NC}      ${GREEN}$success_count${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Failed:${NC}         ${RED}$failed_count${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Output dir:${NC}     ${GREEN}$output_dir${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    
    if [[ $failed_count -gt 0 ]]; then
        echo ""
        echo -e "${RED}❌ Failed sites:${NC}"
        for failed_site in "${failed_sites[@]}"; do
            echo -e "  • $failed_site"
        done
    fi
    
    if [[ $success_count -gt 0 ]]; then
        echo ""
        print_info "Successfully created ZIM files are ready for use with Kiwix"
    fi
}

# Main function
main() {
    print_header
    
    # Parse arguments
    case "${1:-}" in
        -h|--help|"")
            print_usage
            exit 0
            ;;
        recommended)
            # Handle recommended sites
            OUTPUT_DIR="${2:-$DEFAULT_OUTPUT_DIR}"
            WORKERS="${3:-$DEFAULT_WORKERS}"
            
            # Validate workers
            if ! validate_workers "$WORKERS"; then
                exit 1
            fi
            
            # Create output directory if it doesn't exist
            if [[ ! -d "$OUTPUT_DIR" ]]; then
                print_info "Creating output directory: $OUTPUT_DIR"
                mkdir -p "$OUTPUT_DIR"
            fi
            
            # Get absolute path for Docker volume mount
            OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
            
            # Check Docker and Zimit image
            print_info "Checking Docker availability..."
            if ! command -v docker >/dev/null 2>&1; then
                print_error "Docker is not installed or not in PATH"
                exit 1
            fi
            
            if ! docker info >/dev/null 2>&1; then
                print_error "Docker daemon is not running or not accessible"
                exit 1
            fi
            print_success "Docker is ready"
            
            print_info "Checking Zimit Docker image..."
            if ! docker image inspect ghcr.io/openzim/zimit >/dev/null 2>&1; then
                print_warning "Zimit image not found locally, pulling..."
                docker pull ghcr.io/openzim/zimit
                print_success "Zimit image is ready"
            else
                print_success "Zimit image is available"
            fi
            
            # Archive all recommended sites
            archive_recommended "$OUTPUT_DIR" "$WORKERS"
            exit 0
            ;;
    esac
    
    # Check minimum required arguments for single URL
    if [[ $# -lt 2 ]]; then
        print_error "Missing required arguments"
        echo ""
        print_usage
        exit 1
    fi
    
    # Parse parameters for single URL
    URL="$1"
    ZIM_NAME="$2"
    OUTPUT_DIR="${3:-$DEFAULT_OUTPUT_DIR}"
    WORKERS="${4:-$DEFAULT_WORKERS}"
    
    # Validate inputs
    echo -e "${WHITE}${BOLD}🔍 Validating parameters...${NC}"
    
    if ! validate_url "$URL"; then
        exit 1
    fi
    print_success "URL format is valid"
    
    if [[ -z "$ZIM_NAME" ]]; then
        print_error "ZIM name cannot be empty"
        exit 1
    fi
    print_success "ZIM name is valid"
    
    if ! validate_workers "$WORKERS"; then
        exit 1
    fi
    print_success "Worker count is valid"
    
    # Create output directory if it doesn't exist
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        print_info "Creating output directory: $OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi
    
    # Get absolute path for Docker volume mount
    OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
    print_success "Output directory ready: $OUTPUT_DIR"
    
    # Check Docker and Zimit image
    print_info "Checking Docker availability..."
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running or not accessible"
        exit 1
    fi
    print_success "Docker is ready"
    
    print_info "Checking Zimit Docker image..."
    if ! docker image inspect ghcr.io/openzim/zimit >/dev/null 2>&1; then
        print_warning "Zimit image not found locally, pulling..."
        docker pull ghcr.io/openzim/zimit
        print_success "Zimit image is ready"
    else
        print_success "Zimit image is available"
    fi
    
    # Create single ZIM file
    if create_single_zim "$URL" "$ZIM_NAME" "$OUTPUT_DIR" "$WORKERS"; then
        echo ""
        print_info "You can now use this ZIM file with Kiwix server or other ZIM readers"
    else
        exit 1
    fi
}

# Run main function with all arguments
main "$@"