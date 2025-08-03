#!/usr/bin/env bash
#
# Map data downloader for Organic Maps (https://organicmaps.app/)
# Downloads .mwm map files for offline navigation
#

BASE_URL="http://omaps.wfr.software/maps"

# Function to get latest folder
get_latest_folder() {
    curl -s "$BASE_URL/" \
      | grep -Eo '[0-9]{6}/' \
      | sed 's|/||' \
      | sort -nr \
      | head -n1
}

# Function to get map filenames
get_map_filenames() {
    local search_term="$1"
    
    latest_folder=$(get_latest_folder)
    if [[ -z "$latest_folder" ]]; then
        echo "[!] Failed to find version folder." >&2
        exit 1
    fi

    FULL_URL="$BASE_URL/$latest_folder"

    filenames=$(curl -s "$FULL_URL/" \
      | grep -Eo 'href="[^"]+\.mwm"' \
      | sed -E 's/^href="//;s/"$//' \
      | sed 's|^\./||' \
      | sort)

    if [[ -n "$search_term" ]]; then
        echo "$filenames" | grep -i "$search_term"
    else
        echo "$filenames"
    fi
}

# Function to download filenames from stdin
download_files() {
    latest_folder=$(get_latest_folder)
    if [[ -z "$latest_folder" ]]; then
        echo "[!] Failed to find version folder." >&2
        exit 1
    fi

    FULL_URL="$BASE_URL/$latest_folder"

    # Create data directory if it doesn't exist
    mkdir -p data

    while IFS= read -r filename; do
        if [[ -n "$filename" ]]; then
            url="$FULL_URL/$filename"
            echo "[*] Downloading: $filename" >&2
            curl -s -L -o "data/$filename" "$url"
            if [[ $? -eq 0 ]]; then
                echo "[✓] Downloaded: data/$filename" >&2
            else
                echo "[!] Failed to download: $filename" >&2
            fi
        fi
    done
}

# Main script logic
case "$1" in
    "list")
        get_map_filenames "$2"
        ;;
    "download")
        download_files
        ;;
    *)
        echo "Map data downloader for Organic Maps (https://organicmaps.app/)" >&2
        echo "Usage: $0 {list [search_term]|download}" >&2
        echo "Examples:" >&2
        echo "  $0 list                    # List all map filenames" >&2
        echo "  $0 list romania           # Search for maps containing 'romania'" >&2
        echo "  $0 list romania | $0 download  # Download Romania maps" >&2
        exit 1
        ;;
esac