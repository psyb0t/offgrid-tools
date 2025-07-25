# 🔥 offgrid-tools 🔥

fuck the grid 🖕 Docker Compose setup for when the internet dies and you still need to get shit done.

## 📋 table of contents

- [📦 what's in the box](#-whats-in-the-box)
- [🚀 the stack](#-the-stack)
- [🎯 getting started](#-getting-started)
- [🌐 where to find your shit](#-where-to-find-your-shit)
- [📋 what the fuck is this anyway](#-what-the-fuck-is-this-anyway)
- [🏴‍☠️ getting .zim files](#️-getting-zim-files)
- [🤖 getting AI models](#-getting-ai-models)
- [💬 IRC chat network](#-irc-chat-network)
- [📦 offline package management](#-offline-package-management)
- [💾 data persistence](#-data-persistence)
- [🚨 troubleshooting](#-troubleshooting)

## 📦 what's in the box

- `docker-compose.yml` - your entire digital survival kit 🛠️
- `save-docker-images.sh` / `load-docker-images.sh` - smuggle containers like digital contraband 🏴‍☠️
- `create-zim.sh` - turn any website into offline archives 🕷️
- `apps/linux/` - offline debian/ubuntu package downloaders with dependency resolution 📦
- `apps/android/` - essential APK collection for sideloading survival apps 📱
- `zim/copy-to-android.sh` - transfer knowledge archives to android devices via ADB 📲
- `apps/linux/utils.sh` - shared utilities for package download scripts (modular architecture) 🔧
- service dirs with data folders for when you need to hoard information 💾

## 🚀 the stack

- **Kiwix** 📚 - offline knowledge server (supports wikipedia, stackoverflow, gutenberg, wiktionary, whatever .zim files you throw at it)
- **Ollama** 🤖 - AI that runs on your hardware, not in some corpo datacenter
- **Open WebUI** 💬 - talk to your AI without sending chat logs to surveillance capitalism
- **Ollama Chat Party** 🎉 - RAG-enabled chat interface with document ingestion capabilities
- **TheLounge** 💬 - web-based IRC client for connecting to IRC networks through your browser
- **InspIRCd** 🌐 - IRC server for hosting your own chat networks and channels

## 🎯 getting started

**prerequisites:**
- Docker and Docker Compose installed
- sudo privileges for directory permissions

**🪟 windows users:**

**option 1: WSL2 (recommended)**
```powershell
# install WSL2 with Ubuntu (run as Administrator in PowerShell)
wsl --install -d Ubuntu

# restart computer, then open Ubuntu terminal and run:
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER

# logout/login to Ubuntu terminal, then continue with setup below
```

**option 2: Docker Desktop**
```powershell
# download and install Docker Desktop from docker.com
# ensure "Use WSL 2 based engine" is enabled in Docker Desktop settings
# open PowerShell or Command Prompt and run:
git clone [repo-url]
cd offgrid-tools

# skip the chmod step (Windows doesn't need it)
# create the directory manually:
mkdir ircd\data

# then run:
docker compose up
```

**option 3: older Windows (without WSL2)**
```powershell
# install VirtualBox + Vagrant, or use Docker Toolbox (legacy)
# or upgrade to Windows 10/11 for better Docker support
```

**setup:**
```bash
git clone [repo-url]
cd offgrid-tools

# fix IRC server permissions (required for InspIRCd)
sudo chown -R 10000:10000 ./ircd/data

# start the stack
docker compose up

# access your services:
# - IRC chat: http://localhost:9000 (no login needed, auto-joins #general)
# - AI chat: http://localhost:3000 
# - Knowledge: http://localhost:8080
# - RAG chat: http://localhost:8000 (password: offgrid123)
```

become ungovernable 😈

## 🌐 where to find your shit

- **Kiwix** 📚 - `http://localhost:8080` - offline knowledge server with .zim archives
- **Open WebUI** 💬 - `http://localhost:3000` - chatgpt-like interface for ollama models
- **Ollama Chat Party** 🎉 - `http://localhost:8000` - RAG chat with document uploads (password: `offgrid123`)
- **TheLounge** 💬 - `http://localhost:9000` - web interface for IRC networks (no login needed, auto-joins #general)
- **InspIRCd** 🌐 - `localhost:6667` (plain) / `localhost:6697` (SSL) - IRC server for network chat
- **Ollama API** 🤖 - `http://localhost:11434` - raw AI endpoint for API access

### 💬 open webUI features

modern chatgpt-like interface with:

- multiple conversation threads
- file upload support (PDFs, images, documents)
- model switching during conversations
- user management and permissions
- custom prompts and templates
- conversation history
- dark/light themes
- mobile responsive
- OpenAI-compatible API at `http://localhost:3000/ollama/v1`

first user becomes admin and can manage accounts, configure settings, control model access, and set up custom prompts.

### 🎉 ollama chat party features

RAG-enabled chat interface with enhanced document processing:

- connects to local ollama at `http://ollama:11434`
- drop documents in `/documents` folder for context-aware conversations
- supports: text files (.txt, .md), web content (.html, .htm), PDFs, word docs (.docx), libreoffice (.odt)
- password protected: `offgrid123`
- restart service to reindex new documents: `docker compose restart ollama-chat-party`

## 📋 what the fuck is this anyway

this is a self-contained digital bunker for when shit hits the fan. internet goes down? government censors your access? ISP decides to fuck with you? doesn't matter. this stack runs entirely on your local machine.

**Kiwix** 📚 serves up compressed knowledge archives (.zim files). download wikipedia, stack overflow, project gutenberg, medical texts, survival guides, whatever. all searchable offline. it's like having the library of alexandria on your laptop but without the fire risk.

**Ollama** 🤖 is your local AI that doesn't phone home. runs llama, mistral, code models, whatever. no api keys, no monthly subscriptions, no sending your private thoughts to openai's data mining operation. just raw silicon doing math for you.

**Open WebUI** 💬 gives you a chatgpt-like interface that talks to your local ollama instance. upload documents, ask questions, generate code, whatever. all stays on your hardware.

**Ollama Chat Party** 🎉 is another chat interface with enhanced RAG (retrieval-augmented generation) capabilities. drop documents in the `/documents` folder and it'll ingest them for context-aware conversations. password protected because even in the apocalypse you need some security.

the beauty is everything talks to everything else through docker's internal network. no external dependencies once it's running.

## 🏴‍☠️ getting .zim files

### download existing archives

get ZIM files from these sources:

- **official content**: https://wiki.kiwix.org/wiki/Content
- **direct downloads**: https://download.kiwix.org/zim/
- **popular archives**:
  - `wikipedia_en_all_novid.zim` - english wikipedia without videos
  - `stackoverflow.com_en_all.zim` - stack overflow for debugging offline
  - `developer.mozilla.org_en_all.zim` - MDN web docs
  - `wiktionary_en_all_novid.zim` - dictionary/thesaurus

place .zim files in `./zim/data/` directory. kiwix server automatically serves all files found there. access at `http://localhost:8080`.

### create your own archives 🕷️

use `create-zim.sh` to turn any website into a .zim file:

```bash
# basic usage - archives a site to ./zim/data/
./create-zim.sh https://example.com example.com

# custom output directory and worker count
./create-zim.sh https://docs.python.org python-docs ./archives 25

# archive localhost services (great for documentation sites)
./create-zim.sh http://localhost:3000 my-local-app
```

**dependencies:** Docker (checks daemon status), validates URLs and worker count (1-100)

the script handles everything: pulls the zimit docker image, validates urls, creates directories, shows progress. works with any website that doesn't actively hate crawlers. includes help with `./create-zim.sh --help`.

### transfer to android 📱

use `zim/copy-to-android.sh` to transfer ZIM files to Android Kiwix app:

```bash
cd zim
./copy-to-android.sh data/my-archive.zim  # requires ADB and USB debugging
```

## 🤖 getting AI models

**prerequisites:**

- NVIDIA GPU with docker GPU support (nvidia-container-toolkit) for best performance
- verify GPU access: `nvidia-smi`
- docker-compose.yml pre-configured with nvidia-docker GPU support

**pull models (requires internet):**

```bash
# small models for testing/fast inference
docker exec offgrid-tools-ollama ollama pull qwen2.5:0.5b    # ~400MB, very fast
docker exec offgrid-tools-ollama ollama pull llama3.2:1b     # ~1GB, fast chat

# balanced models
docker exec offgrid-tools-ollama ollama pull llama3.2:3b     # ~2GB, good performance

# specialized models
docker exec offgrid-tools-ollama ollama pull codellama:7b    # ~4GB, code generation
docker exec offgrid-tools-ollama ollama pull mistral:7b      # ~4GB, general purpose
```

**model management:**

```bash
# list downloaded models
docker exec offgrid-tools-ollama ollama list

# remove a model
docker exec offgrid-tools-ollama ollama rm llama3.2:1b

# show model info
docker exec offgrid-tools-ollama ollama show llama3.2:1b
```

**performance:**

- **with GPU**: llama3.2:1b (~100+ tokens/sec), llama3.2:3b (~50+ tokens/sec), codellama:7b (~20+ tokens/sec)
- **CPU only**: significantly slower, use smaller models like qwen2.5:0.5b

**API access:**

- **ollama API**: `http://localhost:11434`
- **models list**: `http://localhost:11434/api/tags`
- **health check**: `http://localhost:11434/api/version`

models are stored in `./ollama/data/` and persist between container restarts for offline use.

## 💬 IRC chat network

run your own private IRC network for local/network communication when other services fail.

**components:**

- **InspIRCd server** 🌐 - hosts IRC channels and manages connections
- **TheLounge web interface** 💬 - shared web-based IRC interface (multi-user)

**connection details:**

- **IRC server**: `localhost:6667` (plain text) or `localhost:6697` (SSL/TLS)
- **web interface**: `http://localhost:9000` - access IRC through browser with persistent connections

**getting started:**

1. **fix permissions first**: `sudo chown -R 10000:10000 ./ircd/data` (required for InspIRCd to write config files)
2. **start services**: `docker compose up` - wait for InspIRCd to finish loading modules  
3. **access public interface**: anyone goes to `http://your-ip:9000` - no login required, automatically connects to local IRC
4. **start chatting**: users automatically join `#general` channel and can create new channels with `/join #channelname`
5. **create channels**: type `/join #tech`, `/join #random`, etc. to make new channels - first person becomes channel operator
6. **invite others**: share the URL `http://your-ip:9000` - everyone sees the same channels and chats together

**configuration details:**
- TheLounge runs in **public mode** (no accounts needed)
- **auto-connects** to local InspIRCd server (`ircd:6667`)
- **auto-joins** `#general` channel on connection
- **temporary sessions** - IRC connection ends when browser closes (trade-off for no-login convenience)
- **restart thelounge** if you modify config: `docker compose restart thelounge`

**advanced usage:**

- **external IRC clients**: connect xchat, mIRC, weechat to `localhost:6667`
- **network access**: other machines connect to `your-ip:6667` (IRC) and `your-ip:9000` (web)
- **persistence**: TheLounge keeps everyone connected even when browsers are closed  
- **multi-user**: shared TheLounge instance - everyone sees the same channels and chats together

**configuration:** IRC server settings in `./ircd/data/` directory, TheLounge settings in `./thelounge/data/`

## 📦 offline package management

when package managers fail you and repos go dark, this is your lifeline. download packages when you have internet, install them when you don't.

### 🐧 linux packages

**location:** `apps/linux/deb/`

comprehensive Debian/Ubuntu package collection with automatic dependency resolution and OS/architecture detection.

**available package groups:**

- **🐳 docker**: container runtime and development tools (docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin)
- **📱 adb**: android development tools (android-tools-adb, android-tools-fastboot, android-sdk-platform-tools-common)
- **🐹 programming languages**: golang-go (latest via PPA), python3, python3-pip, python3-venv
- **📝 development tools**: nano, geany, terminator
- **🖥️ applications**: virtualbox-7.1 (Oracle official), chromium-browser, gimp, ffmpeg, supervisor

**download all packages while online:**

```bash
cd apps/linux/deb
./download.sh     # downloads ALL packages with dependencies (10 parallel downloads)
./download.sh 20  # faster with 20 parallel downloads
./download.sh 5   # slower but lighter on network with 5 parallel downloads
```

**install packages offline:**

```bash
cd apps/linux/deb
sudo ./install.sh  # installs all downloaded packages (requires sudo for dpkg)
```

**advanced features:**

- **intelligent dependency resolution**: uses clean Docker container to get complete dependency chains
- **parallel downloads**: configurable concurrent downloads (default 10, up to 20+ for fast networks)
- **fault tolerance**: continues downloading even if some packages fail resolution
- **deduplication**: shared dependencies downloaded only once
- **comprehensive reporting**: shows which packages succeeded/failed with detailed summaries
- **repository integration**: automatically sets up Docker, Go PPA, and VirtualBox repositories
- **OS detection**: packages organized by `ubuntu-24.04-amd64` etc.
- **clean interface**: minimal logging with emoji progress indicators and full URL visibility
- **error handling**: detailed error reporting with specific failure reasons (404, timeout, DNS errors)
- **resumable downloads**: skips already downloaded files automatically
- **interactive cleanup**: prompts to delete existing files before downloading
- **automatic dependency fixing**: runs `apt-get install -f` to resolve broken dependencies after installation

**how it works:**

the system spins up a clean Docker container matching your OS (uses `${OS_NAME}:${OS_VERSION}` format), silently sets up all required repositories (Docker official, Go PPA, VirtualBox Oracle), tests each package individually for dependency resolution using `apt-get --print-uris`, then downloads successful packages with all their dependencies to a unified directory. using clean base images ensures all dependencies are captured, including basic packages like python3.

**technical details:**

- uses Docker exec commands with individual package checking for maximum reliability
- extracts full URLs from apt-get output and downloads with wget in parallel
- handles URL encoding/decoding automatically for proper filename storage
- provides real-time progress with package resolution status and download results
- automatically cleans up Docker containers and temporary files on interruption

### 📱 android packages

**location:** `apps/android/apk/`

essential apps for when google play store fails you. curated collection of survival-focused, offline-ready applications.

**dependencies:** curl, file command (optional for APK verification)

**step 1:** download all essential apps:

```bash
cd apps/android/apk
./download.sh  # downloads curated collection of offline-ready apps (prompts to clean existing files)
```

**step 2:** install to android device (connect it to usb first and enable usb debugging):

```bash
./install.sh   # installs all APKs via ADB automatically (detects multiple devices, auto-reinstalls existing apps)
```

**included survival apps:**

**📚 knowledge & productivity:**

- **kiwix offline reader** - access wikipedia, stack overflow, and other content offline
- **f-droid app store** - open source alternative to google play

**🛠️ system & development:**

- **termux terminal** - full linux environment with package manager
- **vlc media player** - plays any video/audio format

**🗺️ navigation & maps:**

- **organic maps** - offline maps based on openstreetmap data

**💬 secure communication:**

- **briar messenger** - decentralized messaging via mesh networks
- **briar mailbox** - store-and-forward messaging for briar
- **bitchat p2p** - peer-to-peer chat using bitcoin network

**installation features:**

- automatically finds all downloaded APKs
- shows file names and sizes before installing
- checks ADB and device connection
- installs to all connected devices
- handles reinstalls and provides detailed progress
- pretty output with success/failure tracking

**requirements:**

- ADB (android debug bridge) installed
- android device connected via USB
- USB debugging enabled in developer options

**adding new apps:**
edit the `APKS` array in `download.sh`:

```bash
# format: "app name|URL|custom filename (optional)"
APKS=(
    "signal|https://updates.signal.org/android/Signal.apk"
    "custom name|https://example.com/generic.apk|my_custom_name.apk"
)
```

**use cases:**
perfect for restricted networks, privacy setups, emergency situations, disaster preparedness, air-gapped environments, older android devices, and bulk device provisioning.

**survival philosophy:**
this collection focuses on apps that work when traditional infrastructure fails - offline-first design, decentralized communication, open source preferred, essential functionality, small footprint.

the beauty is you download shit when internet works, install when it doesn't. no network dependencies during installation.

## 💾 data persistence

everything important lives in these folders:

- `./zim/data/` - your .zim knowledge archives (wikipedia, stackoverflow, docs, etc.)
- `./ollama/data/` - AI models and config (maps to `/root/.ollama` in container)
- `./openwebui/data/` - user accounts, chat history, settings, uploads, vector_db
- `./ollama-chat-party/data/` - documents for RAG ingestion and indexing
- `./thelounge/data/` - IRC web client settings, user accounts, chat logs
- `./ircd/data/` - IRC server configuration files and settings
- `./apps/linux/deb/*/data/` - offline linux packages organized by OS/architecture
- `./apps/android/apk/data/` - offline android applications ready for sideloading
- `./docker-images/` - saved container images for air-gapped deployment

**directory structure:**

```
offgrid-tools/
├── zim/data/             # ZIM archives for offline knowledge
├── ollama/data/          # AI models and configuration
├── openwebui/data/       # Web UI data and conversations
├── ollama-chat-party/data/ # RAG documents for context
├── thelounge/data/       # IRC web client settings and logs
├── ircd/data/            # IRC server configuration
├── apps/
│   ├── linux/deb/*/data/ # Linux packages by OS/arch
│   └── android/apk/data/ # Android APK files
└── docker-images/        # Container images for offline use
```

back these up. when the apocalypse comes you'll thank yourself.

the `save-docker-images.sh` script includes zimit for website archiving, plus all the usual suspects (offgrid-tools-kiwix, offgrid-tools-ollama, offgrid-tools-openwebui, offgrid-tools-ollama-chat-party, offgrid-tools-thelounge, offgrid-tools-ircd). intelligently checks for updates (compares image IDs) and only saves when changed. `load-docker-images.sh` provides detailed progress tracking and error counting. run save script periodically to keep your container stash fresh.

## 🚨 troubleshooting

### IRC server won't start

**problem:** InspIRCd fails with "Can't write to volume! Please change owner to uid 10000"

**solution:**
```bash
# fix directory permissions
sudo chown -R 10000:10000 ./ircd/data

# restart the stack
docker compose down
docker compose up
```

**why:** InspIRCd container runs as user ID 10000 internally and needs write access to create config files (inspircd.conf, SSL certificates)

### docker permission errors

if you see permission denied errors for other services, check the container's required UID:

```bash
# check what user the container expects
docker compose logs [service-name]

# fix permissions accordingly
sudo chown -R [uid]:[gid] ./[service]/data
```

common UIDs:
- InspIRCd: 10000:10000
- most others: use your regular user (1000:1000) or default docker permissions

### thelounge still asking for login

**problem:** TheLounge shows login screen instead of direct IRC access

**solution:**
```bash
# restart thelounge to pick up config changes
docker compose restart thelounge

# if still not working, check config file
cat ./thelounge/data/config.js | grep "public:"
# should show: public: true,
```

### services won't connect

**problem:** services can't reach each other (ollama, IRC connections fail)

**solution:**
- ensure all services are in the same docker network (`offgrid`)
- wait for all services to fully start before testing connections
- check service names match docker-compose.yml (use `ircd:6667`, not `localhost:6667` from inside containers)

no tracking 🚫 no telemetry 🚫 no bullshit 🚫 just tools that work when everything else fails 💀
