# Linux Package Collection

This directory contains scripts to install a comprehensive collection of Linux packages for offline use. The packages are organized into categories for survival, development, and emergency preparedness scenarios.

## Usage

```bash
# Install comprehensive survival toolkit
./install.sh
```

The install script automatically downloads and installs ~280+ packages across system packages, Python libraries, and Flatpak applications.

## Package Categories

### Development & Programming

**Core Development Tools:**

- **Python 3** - Programming language with scientific libraries (NumPy, SciPy, Matplotlib, PyDub) for data analysis, automation, and audio processing
- **Python3-pip/venv** - Package installer and virtual environment support for isolated Python environments
- **Go** - Fast compiled language ideal for system tools, network applications, and cross-platform development
- **PHP** - Web development language with CLI and FPM for server applications
- **GCC/G++/Make/CMake** - Complete C/C++ development toolchain for system programming and performance-critical applications
- **Git/Git-LFS** - Version control for code and configuration management, essential for tracking changes in offline environments
- **Build-essential** - Meta-package providing essential compilation tools and headers
- **Dpkg-dev** - Debian package development tools for creating custom packages
- **Libc6-dev** - GNU C Library development files for system programming

**Development Environment:**

- **Nano/Vim/Geany** - Text editors ranging from simple to advanced for code editing and configuration
- **GDB/Valgrind** - Debugging tools for finding memory leaks, crashes, and performance issues
- **Pkg-config** - Tool for managing library compilation flags and dependencies
- **Sudo** - Execute commands as another user for system administration

### Containerization & Virtualization

**Docker Ecosystem:**

- **Docker CE** - Containerization platform for running isolated applications and microservices
- **Docker Compose** - Multi-container application orchestration for complex service stacks
- **Containerd** - Low-level container runtime and image management

**Desktop Virtualization:**

- **VirtualBox** - Cross-platform virtualization for running multiple operating systems safely on desktop

**Enterprise Virtualization (QEMU/KVM Stack):**

- **QEMU System** - Full system emulation supporting x86, ARM, MIPS, PowerPC, and SPARC architectures
- **QEMU-utils/QEMU-block-extra** - Additional QEMU utilities and block device drivers
- **QEMU-guest-agent** - Guest agent for better VM integration and management
- **KVM** - Kernel-based virtual machine for hardware-accelerated virtualization
- **Libvirt** - Virtualization management API with daemon and client tools
- **Virt-Manager/Virt-Viewer** - Graphical interfaces for creating and managing virtual machines
- **Bridge-utils/Virtinst** - Network bridging and VM installation tools
- **OVMF/SeaBIOS** - UEFI and legacy BIOS firmware for virtual machines
- **VirtIO drivers** - High-performance paravirtualized drivers for storage and network

**QEMU Display & Graphics:**

- **SDL2 libraries** - Graphics and input libraries for QEMU display support
- **SPICE** - Remote display protocol with client and agent for VM interaction
- **VirGL/Mesa-utils** - Virtual GPU acceleration and OpenGL utilities

**Audio Support for Virtual Machines:**

- **PulseAudio** - Sound server system for routing audio in virtualized environments
- **ALSA-utils** - Advanced Linux Sound Architecture utilities for audio configuration
- **Pavucontrol** - PulseAudio volume control for managing VM audio streams

**Windows Compatibility:**

- **Wine/Winetricks** - Run Windows applications on Linux without Windows installation
- **PlayOnLinux/Lutris** - Gaming-focused Wine frontends for running Windows games

### Communication & Radio (Survival Critical)

**Software Defined Radio:**

- **GNU Radio** - Complete SDR development framework for creating custom radio applications
- **GQRX-SDR** - Real-time spectrum analyzer and receiver with waterfall display
- **RTL-SDR** - Driver support for cheap USB dongles that receive 24MHz-1.7GHz (aviation, emergency services, satellite)
- **gr-osmosdr** - GNU Radio source block for various SDR hardware (RTL-SDR, HackRF, BladeRF)
- **Liquid-DSP** - Digital signal processing library for SDR applications

**Digital Communication Modes:**

- **Fldigi** - Digital mode software supporting PSK31, RTTY, Olivia, and dozens of other protocols
- **QSSTV** - Slow-scan television for sending/receiving images over radio
- **Direwolf** - Software packet radio modem for APRS emergency communication networks
- **Minimodem/Multimon-ng** - Decode various digital data modes and pager signals
- **JS8Call/WSJTX** - Weak signal digital modes for long-distance communication with minimal power

**Ham Radio Applications:**

- **Chirp** - Program handheld radios and manage frequency databases
- **Xastir** - APRS client for tracking vehicles and emergency coordination
- **CQRLog** - Ham radio logging software for contest and general logging
- **Gpredict** - Satellite tracking for amateur radio satellite communication
- **Xlog** - General purpose ham radio logging

**Audio Processing:**

- **SOX** - Swiss Army knife of audio processing (convert, filter, generate tones)
- **BUTT** - Broadcast Using This Tool - stream audio to Icecast servers
- **Mixxx** - DJ software that can also stream to broadcast servers

### Security & Forensics

**Password & Cryptography:**

- **John the Ripper** - Password cracking tool for security testing and recovery
- **Hashcat** - GPU-accelerated password recovery using various attack modes
- **GnuPG** - Implementation of OpenPGP for encryption and digital signatures
- **KeePassXC** - Secure password manager with offline encrypted database

**Digital Forensics:**

- **Foremost** - File carving tool for recovering deleted files from disk images
- **Binwalk** - Firmware analysis tool for extracting embedded files and code
- **Sleuthkit/Autopsy** - Complete digital forensics platform for disk image analysis
- **Scalpel** - Fast file carving based on file headers and footers
- **Safecopy** - Data recovery tool for damaged media with bad sectors
- **RecoverJPEG** - Specialized tool for recovering JPEG images from damaged media

**Network Security:**

- **Wireshark** - Premier network protocol analyzer for troubleshooting and security analysis
- **Nmap** - Network discovery and security scanning with service detection
- **Netcat** - Network Swiss Army knife for port scanning, file transfers, and backdoors
- **TCPdump** - Command-line packet analyzer for real-time network monitoring
- **Ettercap** - Comprehensive network sniffer and man-in-the-middle attack tool

**Wireless Security:**

- **Aircrack-ng** - Complete WiFi security auditing and penetration testing suite
- **MDK4** - WiFi testing tool for denial of service and vulnerability assessment
- **Wavemon** - Wireless network monitoring tool with real-time signal strength
- **Horst** - Lightweight wireless LAN analyzer for 802.11 debugging

**Network Infrastructure:**

- **Hostapd** - Create WiFi access points for honeypots or legitimate hotspots
- **Dnsmasq** - Lightweight DHCP and DNS server for isolated networks
- **Macchanger** - Change MAC addresses for anonymity or troubleshooting

**Exploitation & Testing:**

- **Mitmproxy** - Interactive HTTPS proxy for security testing and debugging
- **Bettercap** - Modern network reconnaissance and attack framework
- **HCXtools** - Tools for capturing and converting WiFi handshakes
- **Crunch** - Wordlist generator for password attacks
- **Hydra/Medusa** - Network logon crackers supporting many protocols

**System Security:**

- **Chkrootkit/Rkhunter** - Rootkit detection tools for compromised systems
- **UFW** - Uncomplicated Firewall for simple iptables management
- **OpenSSH** - Secure remote access and file transfer over encrypted connections

### Hardware & Embedded Systems

**Mobile Device Interface:**

- **Android Debug Bridge (ADB)** - Debug Android devices, install apps, access shell
- **Fastboot** - Flash Android device partitions and unbrick devices
- **Heimdall** - Flash Samsung Android devices via download mode

**Microcontroller Development:**

- **Arduino IDE** - Programming environment for Arduino and compatible microcontrollers
- **PlatformIO** - Professional IoT development platform supporting 1000+ boards
- **AVR-GCC/AVRDUDE** - Complete AVR microcontroller development toolchain
- **AVR-libc** - C library optimized for AVR microcontrollers

**Serial Communication:**

- **Minicom/Picocom** - Terminal emulators for serial console access
- **Screen** - Multiplexer that can also handle serial connections
- **CU** - Call up - simple serial terminal program

**Electronics Design:**

- **KiCad** - Professional PCB design suite with schematic capture and 3D visualization
- **PCB-rnd** - Advanced printed circuit board design tool

**Hardware Programming:**

- **Flashrom** - Read/write BIOS, UEFI, and other firmware chips
- **OpenOCD** - On-chip debugger for ARM and other microprocessors
- **STLink-tools** - Programming tools for STMicroelectronics ARM processors
- **DFU-util** - Device Firmware Upgrade utility for USB-connected devices

**Bluetooth:**

- **Bluez/Bluez-tools** - Official Linux Bluetooth protocol stack
- **Blueman** - Graphical Bluetooth manager
- **Bluez-hcidump** - Bluetooth packet analyzer for protocol debugging

### Scientific & Navigation

**Astronomy & Navigation:**

- **Stellarium** - Planetarium software for celestial navigation and astronomical observation
- **Kstars** - Desktop planetarium with telescope control capabilities

**GPS & Mapping:**

- **QMapShack** - GPS mapping application with offline OpenStreetMap support
- **GPSD** - GPS daemon that makes GPS data available to multiple applications
- **FoxtrotGPS** - Lightweight GPS/GIS application with offline map support

**Scientific Computing:**

- **Octave** - MATLAB-compatible environment for numerical computations
- **Gnuplot** - Command-line driven graphing utility for data visualization
- **SQLite3/SQLiteBrowser** - Embedded database engine with graphical browser

### Manufacturing & Engineering

**3D Design & Manufacturing:**

- **OpenSCAD** - Programmable 3D CAD modeler ideal for mechanical parts
- **Blender** - Professional 3D modeling, animation, and rendering suite
- **Meshlab** - System for processing and editing 3D triangular meshes
- **Slic3r** - G-code generator for 3D printing

**Engineering Analysis:**

- **CalculiX** - Finite element analysis solver for structural and thermal analysis

### Education & Knowledge

**Learning Tools:**

- **Anki** - Spaced repetition flashcard system for memorizing large amounts of information
- **Kalzium** - Periodic table of elements with detailed chemical information
- **Step** - Interactive physics simulation environment

### Office & Productivity

- **LibreOffice** - Complete office suite for documents, spreadsheets, and presentations

### System Administration & Monitoring

**System Monitoring:**

- **Htop** - Interactive process viewer with better interface than top
- **IOtop** - I/O monitoring tool to identify disk usage by process
- **Nethogs** - Network bandwidth monitoring per process
- **Lm-sensors** - Hardware monitoring for temperature, voltage, and fan sensors
- **Smartmontools** - Monitor hard drive health using SMART data
- **Memtester** - Memory testing utility for detecting bad RAM

**Performance & Diagnostics:**

- **Powertop** - Power consumption analyzer and optimization tool
- **Iperf3** - Network bandwidth testing tool
- **MTR** - Network diagnostic tool combining ping and traceroute

**Package Management:**

- **Gdebi** - Simple package installer for .deb files with dependency resolution
- **Flatpak** - Universal application distribution framework
- **PV** - Pipe viewer for monitoring data through Unix pipes

**Infrastructure Monitoring:**

- **NUT** - Network UPS Tools for monitoring uninterruptible power supplies

### Data Recovery & Backup

**Disk Recovery:**

- **TestDisk** - Recover lost partitions and repair filesystem boot sectors
- **GParted** - Graphical partition editor for resizing and managing disk partitions
- **ddrescue** - Data recovery tool for reading damaged media with retry and logging
- **DC3DD/EWF-tools** - Forensic disk imaging tools for evidence acquisition

**File Recovery:**

- **NTFS-3G** - Read/write NTFS filesystems from Linux
- **Gnome Disk Utility** - Graphical disk management and SMART monitoring

**Backup Solutions:**

- **Clonezilla** - Bare metal backup and recovery solution
- **dar** - Differential archiver with encryption and compression
- **rdiff-backup** - Reverse differential backup tool
- **rsync** - Fast incremental file transfer and synchronization
- **Borgbackup** - Deduplicating backup program with encryption
- **Vorta** - Desktop backup client for Borg repositories
- **Duplicity** - Encrypted bandwidth-efficient backup using rsync algorithm

### Archive & Compression

**Archive Formats:**

- **zip/unzip** - Standard ZIP archive creation and extraction
- **rar/unrar** - RAR archive support (unrar is free version)
- **p7zip** - 7-Zip archive format with excellent compression ratios
- **tar/gzip/bzip2/xz-utils** - Standard Unix archive and compression tools
- **zstd** - Facebook's Zstandard compression algorithm (fast compression/decompression)
- **arj/lzip** - Additional archive formats for compatibility
- **cabextract** - Extract Microsoft Cabinet files

### Media Production & Processing

**Media Tools:**

- **FFmpeg** - Swiss Army knife of video/audio processing and conversion
- **ImageMagick** - Command-line image editing and conversion toolkit
- **GIMP** - GNU Image Manipulation Program for advanced photo editing
- **VLC** - Universal media player supporting virtually all media formats

**Content Creation:**

- **Kdenlive** - Professional video editing suite
- **Audacity** - Multi-track audio editor and recorder
- **Calibre** - E-book library management and conversion
- **Espeak-ng** - Text-to-speech synthesizer supporting multiple languages

### Web & Server

**Web Browsers:**

- **Lynx** - Text-based web browser for console environments
- **Epiphany** - Simple GNOME web browser
- **Konqueror** - KDE's file manager that doubles as web browser
- **Chromium** - Open-source version of Google Chrome

**Web Server:**

- **Nginx** - High-performance web server and reverse proxy

### Desktop Environment

**Terminal & Interface:**

- **Terminator** - Advanced terminal emulator with split panes and multiple tabs
- **XFCE4-goodies** - Additional utilities and applications for XFCE desktop environment

### ISO Creation & Live Systems

**ISO Management:**

- **Genisoimage/Xorriso** - Create ISO images from directories
- **Isolinux/Syslinux** - Bootloaders for CD/USB boot media  
- **Mtools/Dosfstools** - MS-DOS filesystem utilities
- **Squashfs-tools** - Compressed read-only filesystem for live CDs
- **Debootstrap** - Bootstrap Debian base system
- **Live-build/Live-config/Live-boot** - Debian Live system creation tools
- **GRUB2** - Grand Unified Bootloader for UEFI and legacy systems
- **Casper** - Scripts for live CD/USB systems
- **Ubiquity** - Ubuntu installer framework with GTK and KDE frontends
- **mkisofs/cdrdao** - Additional ISO creation and CD/DVD burning tools
- **dvd+rw-tools/cdrtools/wodim** - DVD and CD writing utilities for media creation

## Python Packages (via pip)

The installation also includes essential Python libraries:

**SDR & Radio:**

- **PySDR** - Software Defined Radio library for Python
- **fskmodem** - FSK modem implementation
- **rfcat** - Sub-GHz radio hacking library

**Audio & Signal Processing:**

- **soundfile/librosa** - Audio file I/O and analysis
- **pyaudio/sounddevice** - Real-time audio recording and playback

**Security & Networking:**

- **scapy** - Packet manipulation and network scanning
- **cryptography/paramiko** - Cryptographic operations and SSH
- **requests/beautifulsoup4** - HTTP requests and web scraping

**Hardware Interface:**

- **pyserial** - Serial port communication
- **pyusb/pyftdi** - Direct USB device control
- **gpiozero** - GPIO interface for Raspberry Pi compatibility
- **pymodbus** - Industrial Modbus protocol support
- **can** - CAN bus interface for automotive and industrial communication
- **pynput** - Keyboard and mouse automation for controlling systems
- **psutil** - System and hardware monitoring (CPU, memory, disk, network)

**Data Analysis:**

- **pandas/networkx** - Data manipulation and network analysis
- **jupyter/ipython** - Interactive computing environments

**Scientific Computing:**

- **sympy/astropy** - Symbolic math and astronomy calculations
- **geopandas/folium** - Geographic data analysis and mapping

**Medical & Bioinformatics:**

- **pydicom** - Medical imaging library for reading and processing DICOM files from medical scanners
- **nibabel** - Neuroimaging data processing for MRI, fMRI, and other brain imaging formats
- **biopython** - Bioinformatics tools for DNA/RNA sequence analysis, protein structures, and genomics

**Exploitation & Security:**

- **pwntools/angr** - Exploit development and binary analysis
- **capstone/keystone/unicorn** - Disassembly, assembly, and CPU emulation

## Flatpak Applications

**Navigation:**

- **Organic Maps** - Offline navigation with OpenStreetMap data

## Installation Notes

- The install script automatically downloads and resolves all dependencies 
- Repository setup includes Docker CE, Go PPA, and VirtualBox repositories
- Installation handles dependency conflicts and continues on individual package failures
- All operations are logged to `install-packages.log` for troubleshooting
- Python packages are installed with `--break-system-packages` flag for modern systems
- Flatpak packages require Flathub repository setup (handled automatically)
- Total package count: ~280+ across system packages, Python libraries, and Flatpak applications

This comprehensive package collection provides everything needed for offline development, security analysis, emergency communication, and system administration in isolated environments.
