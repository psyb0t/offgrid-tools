#!/bin/bash

# Signal handling for clean exit
cleanup() {
    echo ""
    echo -e "${RED}🛑 Script interrupted by user${NC}"
    echo -e "${YELLOW}⚠️  Cleaning up and exiting...${NC}"
    exit 130
}

# Set up signal traps
trap cleanup SIGINT SIGTERM

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
DEFAULT_OUTPUT_DIR="./data"
DEFAULT_WORKERS=10

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
    echo ""
    echo -e "${WHITE}${BOLD}ARGUMENTS:${NC}"
    echo -e "  ${YELLOW}URL${NC}         ${WHITE}Website URL to archive (required)${NC}"
    echo -e "              ${WHITE}Example: https://example.com${NC}"
    echo ""
    echo -e "  ${BLUE}ZIM_NAME${NC}    ${WHITE}Name for the ZIM file (required)${NC}"
    echo -e "              ${WHITE}Example: example.com${NC}"
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
    echo -e "  ${WHITE}Custom output directory:${NC}"
    echo -e "    $0 https://example.com example.com /home/user/archives"
    echo ""
    echo -e "  ${WHITE}Custom worker count:${NC}"
    echo -e "    $0 https://example.com example.com ./archives 25"
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
    
    echo ""
    echo -e "${WHITE}${BOLD}🚀 Creating ZIM for: $url${NC}"
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

# Main function
main() {
    print_header
    
    # Parse arguments
    case "${1:-}" in
        -h|--help|"")
            print_usage
            exit 0
            ;;
    esac
    
    # Check minimum required arguments
    if [[ $# -lt 2 ]]; then
        print_error "Missing required arguments"
        echo ""
        print_usage
        exit 1
    fi
    
    # Parse parameters
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