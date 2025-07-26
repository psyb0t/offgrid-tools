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
- [License](#license)

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

### Kiwix (Port 8000)
Offline content server that serves ZIM archive files through a web interface. Reads ZIM files you place in `zim/data/` including Wikipedia dumps, educational materials, and archived websites. Essential for accessing knowledge when internet is unavailable. Simply visit the web interface to browse and search offline content - no additional setup required.

### Ollama (Internal Port 11434)
Local AI model server that runs language models completely offline on your hardware. Stores models and configuration in `ollama/data/` directory. Provides ChatGPT-like capabilities without sending data to external services. Not directly accessible from host - access through Open WebUI or Ollama Chat Party. Models are automatically downloaded on first use - larger models require more RAM and benefit from GPU acceleration.

### Open WebUI (Port 8001)
Web-based chat interface for Ollama that provides a modern ChatGPT-like experience. Stores user accounts, chat history, and preferences in `openwebui/data/`. Create your admin account on first visit, then start chatting with local AI models. Supports file uploads, conversation management, and multiple model selection.

### Ollama Chat Party (Port 8002)
Multi-user AI chat room where multiple people can chat with the same AI simultaneously, sharing conversation history. Supports RAG (Retrieval-Augmented Generation) with documents stored in `ollama-chat-party/data/`. Upload documents to enhance AI responses with your own knowledge base. Default password is `offgrid123`.

### InspIRCd (Internal Port 6667)
IRC server for local network chat and communication. Configuration stored in `inspircd/conf/` with logs in `inspircd/logs/`. Provides traditional IRC channels and private messaging within the Docker network. Not directly accessible from host - access through TheLounge web client. Operator credentials: `offgrid` / `offgrid123`.

### TheLounge (Port 8003)
Modern web-based IRC client that connects to the InspIRCd server. Configuration and user data stored in `thelounge/` directory. Provides a Discord-like interface for IRC with persistent connections, file sharing, and modern features. No additional setup needed - automatically connects to the local IRC server.

### Icecast (Port 8004)
Audio streaming server for broadcasting live audio streams to multiple listeners. Creates internet radio stations or live audio feeds. To stream audio, use source clients like BUTT (Broadcast Using This Tool) or Mixxx with server `localhost:8004` and password `offgrid123`. Listeners access streams at `http://localhost:8004/mountpoint`. Perfect for emergency broadcasts, local radio, or streaming music to your network.

### File Server (Port 8005)
Web-based file browser for downloading all offline content via HTTP. Serves files from `apps/*/data/`, `docker-images/`, `zim/data/`, and custom files from `file-server/other-files/`. Simply browse the web interface to download APKs, DEBs, ISOs, Docker images, or any custom files. Supports basic authentication - default credentials: `offgrid` / `offgrid123`.

## Preparing for the Apocalypse

The repo itself is tiny (~1MB), but the real power comes from downloading all the shit you'll need offline.

### Quick Download Everything

```bash
# Download everything at once (Docker images, APKs, packages, ISOs, ZIM archives)
./trigger-downloads.sh
```

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
- Text editor (nano)
- Development tools (Go, Python, PHP, geany IDE, build-essential, gcc, g++, make, cmake, gdb, valgrind)
- Web server (nginx)
- Terminal emulator (Terminator)
- VirtualBox for VMs
- Media tools (FFmpeg, GIMP)
- System monitoring (htop, iotop, nethogs)
- Network tools (Wireshark, nmap, netcat)
- File sync & backup (rsync, BorgBackup, Vorta GUI)
- Software Defined Radio (GQRX)
- Audio streaming (BUTT, Mixxx)
- Security (UFW firewall, KeePassXC password manager, SSH client/server)
- Disk tools (TestDisk, GParted, NTFS-3G, ddrescue, GNOME Disks)
- System utilities (pv progress viewer)

### Bootable Images

Download essential bootable operating systems and tools for recovery and deployment:

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
- **GParted Live** - Disk partitioning and recovery tool. Essential for managing disk partitions, data recovery, and system repair when systems won't boot.

### Web Content Archives

#### Download Pre-made Archives

Visit https://library.kiwix.org/ to browse and download ready-made ZIM archives including Wikipedia dumps, educational content, reference materials, and curated collections. Simply download the ZIM files and place them in `zim/data/`.

#### Download Curated Archives

```bash
cd zim

# Download essential development and survival content
./download.sh
```

**Archives included:**

- **FreeCodeCamp** - Learn to code with tutorials and interactive lessons
- **Termux Documentation** - Complete Android terminal emulator documentation  
- **Military Medicine** - Emergency medical procedures and combat medicine
- **Programming Documentation** - C++, Go, Docker, JavaScript, C, CSS, HTML, Nginx, Linux man pages
- **Open Data Structures** - Computer science algorithms and data structures textbook
- **Simple Wikipedia** - Simplified Wikipedia articles in basic English
- **Ham Radio Stack Exchange** - Amateur radio Q&A for emergency communications
- **Open Music Theory** - Music theory education and reference materials
- **Based Cooking** - Practical cooking recipes and techniques
- **Food Preparation Guide** - Essential food preparation and preservation techniques

#### Create Custom Archives

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
- Ollama Chat Party: password is `offgrid123`
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

## License

WTFPL - Do What The Fuck You Want To Public License. See [LICENSE](LICENSE) file.

Stay independent. 🔥
