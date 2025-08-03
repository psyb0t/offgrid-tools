#!/bin/bash

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/install-packages.log"

# Define packages to install
PACKAGES=(
    # ============================================================================
    # DEVELOPMENT & PROGRAMMING
    # ============================================================================
    # Programming Languages & Environments
    "python3" "python3-pip" "python3-venv" "python3-numpy" "python3-scipy" "python3-matplotlib" "python3-pydub"
    "golang-go"
    "php" "php-fpm" "php-cli"
    "build-essential" "gcc" "g++" "make" "cmake" "gdb" "valgrind"
    "dpkg-dev" "pkg-config" "libc6-dev"

    # Development Tools
    "git" "git-lfs"
    "nano" "vim" "geany"
    "sudo"

    # Containerization & Virtualization
    "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
    "virtualbox"

    # QEMU/KVM Full Virtualization Stack
    "qemu-system" "qemu-utils" "qemu-user-static" "qemu-kvm" "qemu-system-x86"
    "libvirt-daemon-system" "libvirt-clients" "bridge-utils" "virtinst" "virt-manager" "virt-viewer"
    "ovmf" "seabios" "cpu-checker"

    # Additional QEMU Tools & Features
    "qemu-block-extra" "qemu-guest-agent" "qemu-system-arm" "qemu-system-mips" "qemu-system-misc"
    "qemu-system-ppc" "qemu-system-sparc" "qemu-efi-aarch64" "qemu-efi-arm"

    # QEMU Display & Performance Optimization
    "libsdl2-dev" "libsdl2-2.0-0" "libsdl2-image-2.0-0" "libsdl2-mixer-2.0-0"
    "libspice-server1" "spice-client-gtk" "spice-vdagent"
    "libvirgl1" "mesa-utils" "xserver-xorg-video-qxl"

    # VirtIO Drivers & Tools
    "virtio-win" "libvirt-daemon-driver-qemu" "libvirt-daemon-driver-storage-rbd"
    "libvirt-daemon-driver-network" "libvirt-daemon-driver-nodedev"

    # UEFI Firmware & Boot
    "ovmf-ia32" "qemu-efi" "edk2-ovmf" "ipxe-qemu"

    # Audio Support for VMs
    "pulseaudio" "alsa-utils" "pavucontrol"

    # Wine - Windows Application Compatibility Layer
    "wine" "winetricks" "playonlinux" "lutris"
    "wine32" "wine64" "libwine" "wine-binfmt"
    "winbind" "zenity"

    # XFCE4 Desktop Environment & Goodies
    "xfce4-goodies"

    # ISO Management & Creation Tools
    "genisoimage" "xorriso" "isolinux" "syslinux" "syslinux-utils" "mtools" "dosfstools"
    "squashfs-tools" "debootstrap" "live-build" "live-config" "live-boot"
    "grub2-common" "grub-pc-bin" "grub-efi-amd64-bin" "grub-efi-ia32-bin"
    "casper" "ubiquity" "ubiquity-frontend-gtk" "ubiquity-frontend-kde"
    "mkisofs" "cdrdao" "dvd+rw-tools" "cdrtools" "wodim"

    # ============================================================================
    # COMMUNICATION & RADIO (SURVIVAL CRITICAL)
    # ============================================================================
    # Software Defined Radio
    "gqrx-sdr" "gnuradio-dev" "gr-osmosdr" "rtl-sdr"
    "libliquid-dev" "libliquid1"

    # Digital Modes & Protocols
    "fldigi" "qsstv" "direwolf" "multimon-ng" "minimodem"
    "js8call" "wsjtx"

    # Ham Radio Tools
    "chirp" "xastir" "cqrlog" "gpredict"

    # Emergency & Survival Radio
    "xlog"

    # Audio Processing
    "sox" "butt" "mixxx"

    # ============================================================================
    # SECURITY & FORENSICS
    # ============================================================================
    # Password & Hash Cracking
    "john" "hashcat"

    # Digital Forensics
    "foremost" "binwalk" "sleuthkit" "autopsy"
    "scalpel" "safecopy" "recoverjpeg"

    # System Security
    "chkrootkit" "rkhunter" "ufw"
    "openssh-client" "openssh-server"
    "keepassxc" "gnupg"

    # Network Security & Analysis
    "wireshark" "nmap" "netcat-openbsd"
    "tcpdump" "ettercap-text-only" "dsniff" "macchanger"
    "aircrack-ng" "mdk4" "wavemon" "horst"
    "hostapd" "dnsmasq"

    # Network Exploitation
    "mitmproxy" "bettercap" "hcxtools"
    "crunch" "maskprocessor" "hydra" "medusa"

    # Hardware Hacking & Reverse Engineering
    "flashrom" "openocd" "stlink-tools" "dfu-util" "libftdi1-dev"
    "sigrok" "pulseview" "radare2"

    # Radio Frequency Exploitation
    "hackrf" "gr-gsm" "rtl-433"
    "libfftw3-dev"              # dump1090-mutability removed from Ubuntu 24.04

    # USB/Serial Exploitation
    "usbutils" "socat"

    # Bluetooth/Wireless Hacking
    "bluez-hcidump"

    # Forensics & Data Extraction
    "dc3dd" "ewf-tools"

    # Mobile Device Hacking
    "heimdall-flash"

    # Environmental Monitoring & Physical World
    "lm-sensors" "smartmontools" "memtester"
    "gpsd" "foxtrotgps"

    # Power Management & Infrastructure
    "nut" "powertop" "iperf3" "mtr"

    # ============================================================================
    # HARDWARE & EMBEDDED SYSTEMS
    # ============================================================================
    # Mobile Device Tools
    "android-tools-adb" "android-tools-fastboot"

    # Arduino & Microcontroller Programming
    "arduino" "arduino-core" "avrdude" "avr-libc" "gcc-avr" "platformio"

    # Serial Communication
    "minicom" "picocom" "screen" "cu"

    # Electronics Design
    "kicad"

    # Bluetooth
    "bluetooth" "bluez" "bluez-tools" "blueman"

    # ============================================================================
    # NAVIGATION & MAPPING
    # ============================================================================
    "stellarium" "kstars"        # Astronomy & celestial navigation
    "qmapshack"                  # Offline mapping with OSM data import

    # ============================================================================
    # MANUFACTURING & REPAIR
    # ============================================================================
    "openscad"                   # CAD design (freecad removed - not in Ubuntu 24.04)
    "blender" "meshlab" "slic3r" # 3D modeling & printing

    # Electronics Design & Manufacturing
    "pcb-rnd"                    # PCB design

    # Mechanical Engineering
    "calculix-ccx"               # Finite element analysis

    # ============================================================================
    # EDUCATION & KNOWLEDGE
    # ============================================================================
    "anki"                       # Spaced repetition learning
    "kalzium"                    # Periodic table
    "step"                       # Physics simulation

    # ============================================================================
    # OFFICE & PRODUCTIVITY
    # ============================================================================
    "libreoffice"                # Office suite

    # ============================================================================
    # SCIENTIFIC COMPUTING
    # ============================================================================
    "octave"                     # MATLAB alternative
    "gnuplot"                    # Data visualization
    "sqlite3" "sqlitebrowser"    # Database tools

    # ============================================================================
    # SYSTEM ADMINISTRATION & MONITORING
    # ============================================================================
    "htop" "iotop" "nethogs"     # System monitoring
    "pv"                         # Progress viewer
    "gdebi" "flatpak"            # Package installer

    # ============================================================================
    # DATA RECOVERY & BACKUP
    # ============================================================================
    "testdisk" "gparted" "ntfs-3g" "ddrescue" "gnome-disk-utility"
    "clonezilla" "dar" "rdiff-backup"
    "rsync" "borgbackup" "vorta"

    # ============================================================================
    # ARCHIVE & COMPRESSION
    # ============================================================================
    "zip" "unzip" "rar" "unrar-free" "p7zip-full"
    "tar" "gzip" "bzip2" "xz-utils" "zstd" "arj" "lzip" "cabextract"

    # ============================================================================
    # MEDIA PRODUCTION & PROCESSING
    # ============================================================================
    "ffmpeg" "imagemagick" "gimp" "vlc"
    "kdenlive" "audacity" "calibre"
    "espeak-ng"                  # Text-to-speech

    # ============================================================================
    # WEB BROWSING & SERVERS
    # ============================================================================
    "lynx" "epiphany-browser" "konqueror" "chromium-browser"
    "nginx-full"

    # ============================================================================
    # TERMINAL & UTILITIES
    # ============================================================================
    "terminator"
)

# Define Python packages to install via pip
PIP_PACKAGES=(
    # SDR & Signal Processing
    "PySDR"                 # Software Defined Radio library for Python
    "fskmodem"              # FSK modem implementation for Python
    # "pyminmodem"          # Not available on PyPI - use minimodem command line tool instead

    # Audio & DSP (additional to system packages)
    "soundfile"            # Audio file I/O
    "librosa"              # Audio analysis library

    # SDR/Radio
    "pyaudio"              # Audio I/O for Python
    "sounddevice"          # Audio recording/playback
    "pyserial"             # Serial port communication

    # Security/Cryptography
    "scapy"                # Packet manipulation library
    "cryptography"         # Cryptographic recipes and primitives
    "paramiko"             # SSH2 protocol library
    "requests"             # HTTP library
    "beautifulsoup4"       # Web scraping

    # Data Analysis
    "pandas"               # Data analysis and manipulation
    "networkx"             # Network analysis
    "jupyter"              # Interactive computing environment
    "ipython"              # Enhanced interactive Python

    # Hardware Interface
    "gpiozero"             # GPIO interface (for Raspberry Pi compatibility)
    "pyusb"                # Direct USB device control
    "pyftdi"               # FTDI USB-to-serial/GPIO chips
    "pynput"               # Keyboard/mouse automation
    "psutil"               # System hardware monitoring
    "pymodbus"             # Modbus protocol for industrial devices
    "can"                  # CAN bus interface

    # Arduino/Microcontroller Programming (platformio already in system packages)
    "esptool"              # ESP32/ESP8266 programming tool
    "adafruit-ampy"        # MicroPython file management
    # micropython-lib removed - installation issues

    # Raspberry Pi Tools
    "rpi-imager"

    # Offline Maps/GIS
    "folium"               # Interactive maps
    "geopandas"            # Geographic data analysis
    "shapely"              # Geometric objects manipulation

    # Medical/Health
    "pydicom"              # Medical imaging (DICOM files)
    "nibabel"              # Neuroimaging data
    "biopython"            # Bioinformatics tools

    # Agriculture/Navigation/Astronomy
    "ephem"                # Astronomical calculations
    "pyephem"              # Astronomical positions

    # Power/Energy Management
    "pvlib"                # Solar power calculations
    "pyomo"                # Optimization for energy systems

    # Weather/Climate
    "metpy"                # Meteorology calculations

    # Backup/Data Preservation
    "duplicity"            # Encrypted backup

    # Scientific Computing
    "sympy"                # Symbolic mathematics
    "astropy"              # Astronomy calculations

    # Hacking & Exploitation Libraries
    "pwntools"             # CTF/exploit development
    "angr"                 # Binary analysis platform
    "keystone-engine"      # Assembler framework
    "capstone"             # Disassembly framework
    "unicorn"              # CPU emulator framework
    "rfcat"                # Sub-GHz radio hacking
    # python-bluez removed - doesn't work in Python 3.12
)

# Define Flatpak packages to install
FLATPAK_PACKAGES=(
    "app.organicmaps.desktop"
)

# Logging function
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

# Initialize log file
echo "=== Package Installation Log ===" > "$LOG_FILE"
log "Started package installation process"

# Update package lists
log "📦 Updating package lists..."
sudo apt-get update

# Add required repositories
log "🐳 Adding Docker repository..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common wget
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log "🐹 Adding Go PPA..."
sudo add-apt-repository -y ppa:longsleep/golang-backports

log "📦 Adding VirtualBox repository..."
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc 2>/dev/null | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null

sudo apt-get update

# Install packages
log "📦 Installing system packages..."
for package in "${PACKAGES[@]}"; do
    log "Installing: $package"

    if ! sudo apt-get install -y "$package" 2>&1 | tee -a "$LOG_FILE"; then
        log "❌ FAILED: $package (continuing with other packages)"
    fi
done

log "✅ System package installation completed!"

# Install Python packages via pip
log "🐍 Installing Python packages via pip..."
for package in "${PIP_PACKAGES[@]}"; do
    log "Installing Python package: $package"

    if ! python3 -m pip install --user --no-cache-dir --break-system-packages "$package" 2>&1 | tee -a "$LOG_FILE"; then
        log "❌ FAILED: $package (pip) (continuing with other packages)"
    fi
done

log "✅ Python package installation completed!"

# Setup Flatpak and install Flatpak packages
log "📦 Setting up Flatpak and adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "📦 Installing Flatpak packages..."
for package in "${FLATPAK_PACKAGES[@]}"; do
    log "Installing Flatpak package: $package"
    
    if ! flatpak install -y flathub "$package" 2>&1 | tee -a "$LOG_FILE"; then
        log "❌ FAILED: $package (flatpak) (continuing with other packages)"
    fi
done

log "✅ Flatpak package installation completed!"
log "🎉 All packages installed! Check $LOG_FILE for details."
