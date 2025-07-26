# 🔥 offgrid-tools 🔥

fuck the grid 🖕

Docker Compose setup for when the internet dies and you still need to get shit done.

## Table of Contents

- [What the hell is this?](#what-the-hell-is-this)
- [Quick Start (if you're in a hurry)](#quick-start-if-youre-in-a-hurry)
- [Services Overview](#services-overview)
- [Preparing for the Apocalypse](#preparing-for-the-apocalypse)
  - [Download Docker Images](#download-docker-images)
  - [Android Apps](#android-apps)
  - [Linux Packages](#linux-packages)
  - [Web Content Archives](#web-content-archives)
- [Running the Stack](#running-the-stack)
- [Ports & Access](#ports--access)
- [Data & Storage](#data--storage)
- [Troubleshooting](#troubleshooting)

## What the hell is this?

This is a completely self-contained offline environment that runs on Docker. When the internet goes to shit, power grids fail, or you just want to tell Big Tech to fuck off, you'll have:

- **Local AI chat** (no OpenAI bullshit needed)
- **Offline Wikipedia & web archives** (actual useful knowledge)
- **IRC server & client** (real chat, not surveillance capitalism)
- **Audio streaming & radio** (broadcast to your local network, monitor emergency frequencies)
- **Development tools** (code without the cloud)
- **Mobile app installer** (side-load apps when Google Play is down)

The whole thing is designed to work with **zero internet connection**. Everything gets downloaded once, then you're independent.

## Quick Start (if you're in a hurry)

```bash
# Clone this repo
git clone https://github.com/psyb0t/offgrid-tools.git
cd offgrid-tools

# Start the services
docker-compose up
```

**Note:** This repo has only been tested on Ubuntu for now. If you encounter bugs on other operating systems, please create an issue or submit a pull request with the fix.

But seriously, read the rest or you'll be fucked when you actually need this offline.

## Services Overview

| Service               | Port  | What it does                                      | Dependencies    |
| --------------------- | ----- | ------------------------------------------------- | --------------- |
| **Kiwix**             | 8080  | Serves offline web content (Wikipedia, etc.)      | None            |
| **Ollama**            | 11434 | Local AI models (like ChatGPT but yours)          | GPU recommended |
| **Open WebUI**        | 3000  | Pretty web interface for AI chat                  | Ollama          |
| **Ollama Chat Party** | 8000  | Multi-user AI chat room with shared history & RAG | Ollama          |
| **InspIRCd**          | 6667  | IRC server for local network chat                 | None            |
| **TheLounge**         | 9000  | Web-based IRC client                              | InspIRCd        |
| **Icecast**           | 8001  | Audio streaming server for radio/podcasts         | None            |
| **File Server**       | 8002  | Download APKs, DEBs, ISOs via web browser         | None            |

## Preparing for the Apocalypse

The repo itself is tiny (~1MB), but the real power comes from downloading all the shit you'll need offline.

### Download Docker Images

Save all the container images locally so you don't need to pull from registries:

```bash
# Download container images
./save-docker-images.sh

# Later, load them on an offline machine
./load-docker-images.sh
```

This downloads:

- AI server (Ollama)
- Web UIs for AI chat
- Offline content server (Kiwix)
- IRC server & client
- Audio streaming server (Icecast)
- Web server (Nginx)
- Development environments (Python, Go, Ubuntu)

### Android Apps

Get essential Android apps for when Google Play is unavailable:

```bash
cd apps/android/apk

# Download curated collection of survival apps
./download.sh

# Install them via ADB when needed
./install.sh
```

**Apps included:**

- **Kiwix** - Reader app for ZIM archive files that can contain offline Wikipedia, educational content, or any archived websites. Essential for accessing downloaded knowledge databases when internet is down.
- **F-Droid** - Open source app store for privacy-focused apps that work without Google services. Critical for building an offline toolkit independently.
- **Termux** - Full Linux terminal environment on Android with programming languages and security tools. Essential for technical users needing development tools offline.
- **VLC** - Universal media player for any audio/video format stored locally. Valuable for instructional videos, emergency broadcasts, and entertainment.
- **Organic Maps** - Completely offline navigation with OpenStreetMap data including hiking trails. Critical for GPS navigation in remote areas without cellular coverage.
- **Briar Messenger** - Secure decentralized messaging via Bluetooth/WiFi without internet or servers. Essential for emergency communication when networks are down.
- **Briar Mailbox** - Message relay service for Briar that stores encrypted messages when recipients are offline. Maintains communication continuity in survival groups.
- **BitChat** - Creates Bluetooth mesh networks for encrypted messaging across up to 7 device hops without internet. Revolutionary for survival communication and emergency coordination.
- **KeePassDX** - Secure password manager that works completely offline with encrypted database files. Critical for maintaining access to accounts and services when internet-based password managers fail.

### Linux Packages

Pre-download Linux packages for offline installation:

#### Ubuntu

```bash
cd apps/linux/deb

# Download .deb packages
./download.sh

# Install them when offline
sudo ./install.sh
```

**Packages included:**

- Docker & Docker Compose
- Android tools (ADB, Vysor)
- Programming languages (Go, Python)
- Development tools (editors, etc.)
- Terminal emulator (Terminator)
- VirtualBox for VMs
- Media tools (FFmpeg, GIMP)
- System monitoring (htop, iotop, nethogs)
- Network analysis (Wireshark, nmap)
- File sync & backup (rsync, BorgBackup, Vorta GUI)
- Software Defined Radio (GQRX)
- Audio streaming (BUTT, Mixxx)
- Security (UFW firewall, KeePassXC password manager)
- Disk tools (TestDisk, GParted, NTFS-3G, ddrescue, GNOME Disks)
- System utilities (pv progress viewer)

### Bootable OS Images

Download essential bootable operating systems for recovery and deployment:

```bash
cd apps/iso

# Download curated collection of bootable ISOs
./download.sh

# Create bootable USB drives
sudo ./install.sh
```

**ISOs included:**

- **Ventoy Live CD** - Multi-boot USB creator that can hold multiple ISOs on one drive. Essential for creating versatile rescue drives with multiple operating systems.
- **Xubuntu 24.04.2** - Lightweight Ubuntu with XFCE desktop. Perfect balance of functionality and resource usage for older hardware or minimal systems.
- **Lubuntu 24.04.2** - Ultra-lightweight Ubuntu with LXQt desktop. Ideal for very old hardware or systems with limited RAM and storage.
- **Kali Linux 2025.2** - Security and penetration testing distribution. Critical for network diagnostics, security auditing, and digital forensics in emergency scenarios.
- **Tiny11 23H2** - Stripped-down Windows 11 build without bloatware. Useful when Windows compatibility is required but resources are limited.
- **TinyCore Linux CorePlus** - Extremely minimal modular Linux that runs entirely in RAM. Installation image with multiple desktop environments (JWM, Fluxbox, IceWM, etc.) and wireless support for creating custom minimal systems.

### Web Content Archives

Create offline copies of websites using ZIM format:

```bash
# Archive any website for offline use
./create-zim.sh https://stackoverflow.com stackoverflow

# Copy ZIM files to Android devices
./zim/copy-to-android.sh data/stackoverflow.zim
```

ZIM files work with Kiwix and contain entire websites with search capability.

## Running the Stack

```bash
# Start everything
docker-compose up

# Start in background
docker-compose up -d

# Start specific services
docker-compose up kiwix ollama

# View logs
docker-compose logs -f

# Stop everything
docker-compose down
```

## Ports & Access

Once running, access services at:

- **http://localhost:8000** - Kiwix (offline web content)
- **http://localhost:8001** - Open WebUI (AI chat interface)
- **http://localhost:8002** - Ollama Chat Party (multi-user AI chat room with RAG support)
- **http://localhost:8003** - TheLounge (IRC web client)
- **http://localhost:8004** - Icecast (audio streaming server)
- **http://localhost:8005** - File Server (download APKs, DEBs, ISOs, ZIM files, Docker images, other files)

**Default credentials:**

- Open WebUI: Create your own admin account on first visit
- IRC operator: `offgrid` / `offgrid123`
- Chat Party: password is `offgrid123`
- Icecast: all passwords are `offgrid123`
- File Server: `offgrid` / `offgrid123` (can be changed with FILE_SERVER_AUTH env var)

## Data & Storage

All important data persists in these directories:

```
ollama/data/          # AI models and SSH keys
openwebui/data/       # Chat history and settings
zim/data/             # Offline web archives
apps/android/apk/data/    # Downloaded APK files
apps/linux/deb/data/     # Downloaded .deb packages
apps/iso/data/           # Downloaded ISO images
docker-images/           # Saved Docker containers
file-server/other-files/ # Custom files for web download
```

Most of this is gitignored - the repo just has the scripts to download everything.

## Troubleshooting

**"Docker not found"**

- Install Docker first, genius

**"No devices connected" (Android stuff)**

- Enable USB debugging on your phone
- Connect via USB and accept the prompt

**"AI models are slow as shit"**

- Get a better GPU or accept your fate
- Models download automatically on first use

**"No GPU"**

- Run ollama without GPU support - remove the device from the `docker-compose.yml` file

**"Can't connect to IRC"**

- Make sure InspIRCd container is running
- Try `docker-compose logs inspircd`

**"I broke everything"**

- `docker-compose down && docker-compose up --build` fixes most shit
- Delete data directories to start fresh (you'll lose everything)

**"This is too complicated"**

- Good luck when the internet goes down 🤷‍♂️

---

Remember: This whole setup works **completely offline**. Once you've downloaded everything, you can run it on an isolated network, in a bunker, or wherever the fuck you want without any external dependencies.

Stay independent. 🔥
