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

# APK List - format: "App Name|URL|Custom Filename (optional)"
APKS=(
    "Kiwix Offline Reader|https://download.kiwix.org/release/kiwix-android/org.kiwix.kiwixmobile.standalone.apk"
    "F-Droid App Store|https://f-droid.org/F-Droid.apk"
    "VLC Media Player|https://get.videolan.org/vlc-android/3.6.3/VLC-Android-3.6.3-arm64-v8a.apk"
    "Termux Terminal|https://github.com/termux/termux-app/releases/download/v0.118.0/termux-app_v0.118.0+github-debug_universal.apk"
    "Organic Maps|https://github.com/organicmaps/organicmaps/releases/download/2025.07.13-9-android/OrganicMaps-25071309-web-release.apk"
    "Briar Messenger|https://briarproject.org/apk/briar.apk|briar_messenger.apk"
    "Briar Mailbox|https://briarproject.org/apk/mailbox.apk|briar_mailbox.apk"
    "BitChat P2P|https://github.com/permissionlesstech/bitchat-android/releases/download/0.7.2/bitchat-0.7.2.apk"
    "KeePassDX|https://github.com/Kunzisoft/KeePassDX/releases/download/4.1.3/KeePassDX-4.1.3-libre.apk"
)

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                    Android APK Downloader                     ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}            Download essential apps for offline use             ${NC}${CYAN}║${NC}"
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
    echo -e "${PURPLE}📱 $1${NC}"
}

# Function to extract filename from URL
get_filename() {
    local url="$1"
    local custom_filename="$2"
    local filename

    # Use custom filename if provided
    if [[ -n "$custom_filename" ]]; then
        echo "$custom_filename"
        return
    fi

    # Try to get filename from URL
    filename=$(basename "$url")

    # If it doesn't look like an APK, try to extract from headers
    if [[ ! "$filename" =~ \.apk$ ]]; then
        filename=$(curl -sI "$url" | grep -i 'content-disposition' | sed -n 's/.*filename="\([^"]*\)".*/\1/p' || echo "")
        if [[ -z "$filename" ]]; then
            # Fallback: generate filename from app name
            filename="downloaded_$(date +%s).apk"
        fi
    fi

    echo "$filename"
}

# Function to download a single APK
download_apk() {
    local app_name="$1"
    local url="$2"
    local custom_filename="$3"
    local filename

    print_downloading "Downloading: $app_name"
    echo -e "  ${CYAN}URL:${NC} $url"

    # Get filename
    filename=$(get_filename "$url" "$custom_filename")
    local filepath="$DATA_DIR/$filename"

    echo -e "  ${CYAN}File:${NC} $filename"

    # Check if file already exists
    if [[ -f "$filepath" ]]; then
        local existing_size=$(du -h "$filepath" | cut -f1)
        print_warning "File already exists ($existing_size), skipping"
        return 2  # Return 2 to indicate "skipped"
    fi

    # Download with progress bar
    if curl -L --fail --progress-bar -o "$filepath" "$url"; then
        local file_size=$(du -h "$filepath" | cut -f1)
        print_success "Downloaded successfully ($file_size)"

        # Verify it's actually an APK file
        if file "$filepath" | grep -q "Android"; then
            echo -e "  ${GREEN}✓${NC} APK file verified"
        else
            print_warning "Downloaded file might not be a valid APK"
        fi

        return 0
    else
        print_error "Failed to download $app_name"
        # Clean up partial download
        [[ -f "$filepath" ]] && rm -f "$filepath"
        return 1
    fi
}

# Main function
main() {
    print_header

    print_info "Essential Android apps for offline/survival scenarios"
    echo ""

    # Create data directory if it doesn't exist
    if [[ ! -d "$DATA_DIR" ]]; then
        print_info "Creating data directory: $DATA_DIR"
        mkdir -p "$DATA_DIR"
    fi

    # Clean up existing data directory option
    if [[ -d "$DATA_DIR" ]] && [[ "$(ls -A "$DATA_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}🗂️  Data directory contains existing files:${NC}"
        ls -lh "$DATA_DIR"/*.apk 2>/dev/null | sed 's/^/  /' || echo "  No APK files found"
        echo ""

        read -p "Clean up existing APKs before downloading? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleaning up existing APK files..."
            rm -f "$DATA_DIR"/*.apk
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
        print_warning "file command not available - APK verification will be skipped"
    else
        print_success "file command is available"
    fi

    echo ""
    echo -e "${WHITE}${BOLD}📋 APK Download List:${NC}"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"

    local count=1
    for apk_entry in "${APKS[@]}"; do
        IFS='|' read -r app_name url custom_filename <<< "$apk_entry"
        echo -e "${CYAN}│${NC} ${YELLOW}$count.${NC} ${WHITE}$app_name${NC}"
        ((count++))
    done

    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    echo ""

    # Download statistics
    local downloaded=0
    local failed=0
    local skipped=0

    # Download each APK
    echo -e "${WHITE}${BOLD}🚀 Starting downloads...${NC}"
    echo ""

    # Temporarily disable exit on error for the download loop
    set +e

    for apk_entry in "${APKS[@]}"; do
        IFS='|' read -r app_name url custom_filename <<< "$apk_entry"

        download_apk "$app_name" "$url" "$custom_filename"
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
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}✅ Downloaded:${NC} $downloaded APKs"
    echo -e "${CYAN}│${NC} ${YELLOW}⏭️  Skipped:${NC}    $skipped APKs (already existed)"
    if [[ $failed -gt 0 ]]; then
        echo -e "${CYAN}│${NC} ${RED}❌ Failed:${NC}     $failed APKs"
    fi
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"

    if [[ -d "$DATA_DIR" ]] && [[ "$(ls -A "$DATA_DIR" 2>/dev/null)" ]]; then
        echo ""
        echo -e "${WHITE}${BOLD}📱 Downloaded APKs:${NC}"
        ls -lh "$DATA_DIR"/*.apk 2>/dev/null | sed 's/^/  /' || echo "  No APK files found"

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
        print_success "All APKs downloaded successfully!"
        echo ""
        print_info "Install these APKs with: adb install <filename>.apk"
        print_info "Or transfer to Android device and install manually"
        print_info "Files are saved in: $DATA_DIR"
    fi
}

# Run main function
main "$@"
