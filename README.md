# offgrid-tools

[![CI](https://github.com/psyb0t/offgrid-tools/actions/workflows/pipeline.yml/badge.svg?branch=main)](https://github.com/psyb0t/offgrid-tools/actions/workflows/pipeline.yml)
[![version](https://raw.githubusercontent.com/psyb0t/offgrid-tools/badges/version.svg)](https://github.com/psyb0t/offgrid-tools/releases)
[![license](https://raw.githubusercontent.com/psyb0t/offgrid-tools/badges/license.svg)](LICENSE)

fuck the grid 🖕

Docker Compose setup for when the internet dies and you still need to get shit done.

## Contents

- [What the hell is this?](#what-the-hell-is-this)
- [Quick start](#quick-start)
- [Services](#services)
  - [Local llama.cpp models](#local-llamacpp-models-llama-directory)
  - [Strata](#strata-port-8080-opt-in)
  - [AI compatibility and updates](#ai-compatibility-and-updates)
- [Preparing for the apocalypse](#preparing-for-the-apocalypse)
  - [Docker images](#docker-images)
  - [Linux packages](#linux-packages)
  - [Offgrid Ubuntu virtual machine](#offgrid-ubuntu-virtual-machine)
  - [Android apps](#android-apps)
  - [Bootable images](#bootable-images)
  - [Web content archives](#web-content-archives)
  - [Offline maps](#offline-maps)
- [Running the stack](#running-the-stack)
- [Ports and access](#ports-and-access)
- [Data and storage](#data-and-storage)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## What the hell is this?

Local services and downloads to keep on hand before the connection goes down:

- Local AI chat
- Wikipedia and web archives
- IRC server and web client
- Audio streaming and radio tools
- Development tools
- Android apps and an ADB installer
- Ubuntu VM with the toolkit pre-installed

Download the images, models and content while online. A clone alone is not an offline installation.

## Quick start

```bash
# Clone this repo
git clone https://github.com/psyb0t/offgrid-tools.git
cd offgrid-tools

# Start the services
docker-compose up
```

Tested on Ubuntu. Prepare the downloads below before relying on it offline.

## Services

### Kiwix (port 8000)

Browse and search ZIM archives from `zim/data/`, including Wikipedia and archived websites.

### Ollama (port 11434)

Runs local language models and stores them in `ollama/data/`. Download each model before going offline. Larger models need more RAM and may benefit from a GPU.

### Open WebUI (port 8001)

Browser chat for Ollama, with file uploads and model selection. Accounts, conversations and settings live in `openwebui/data/`. Create the admin account on first visit.

### Ollama Chat Party (port 8002)

Shared AI chat room with document retrieval (RAG). Documents live in `ollama-chat-party/data/`. Default password: `offgrid123`.

### InspIRCd (internal port 6667)

IRC channels and private messages inside the Docker network, accessed through TheLounge. Configuration: `inspircd/conf/`. Logs: `inspircd/logs/`. Operator credentials: `offgrid` / `offgrid123`.

### TheLounge (port 8003)

Browser IRC client configured for the local InspIRCd server. Keeps connections and user data in `thelounge/`.

### Icecast (port 8004)

Broadcast audio to the local network using a source client such as BUTT or Mixxx. Connect the source to `localhost:8004` with password `offgrid123`. Listeners open `http://localhost:8004/mountpoint`, using the source's mountpoint name.

### File server (port 8005)

Download APKs, DEBs, ISOs and other files over HTTP. Serves `apps/*/data/`, `docker-images/`, `zim/data/` and `file-server/other-files/`. Default basic-auth credentials: `offgrid` / `offgrid123`.

### Local llama.cpp models (llama/ directory)

Run GGUF models with llama.cpp Docker containers.

Adding models:

- Download GGUF format models into `models/gguf/<model-name>/`. llama.cpp and Strata share these files; neither needs a second copy.
- Choose a quantization such as Q4_K_M or Q5_K_M that fits the available memory.

The launchers mount `models/gguf/` read-only at `/app/models`. Pass container paths such as `/app/models/qwen-27b-uncensored/Qwen3.8-27B-Uncensored-Q4_K_M.gguf` to `--model` and `--mmproj`. Both launchers work from any current directory. Port 9000 binds only to localhost; `--port` changes both the server port and its published port. Container images must already be loaded, since these launchers never pull from the internet.

Running models:

```bash
cd llama

# Select a GGUF from the shared directory
./run-cpu-gui.sh --model /app/models/qwen-27b-uncensored/Qwen3.8-27B-Uncensored-Q4_K_M.gguf
./run-gpu-gui.sh --model /app/models/qwen-27b-uncensored/Qwen3.8-27B-Uncensored-Q4_K_M.gguf --ngl 20

# Optional vision projector for this model
./run-gpu-gui.sh --model /app/models/qwen-27b-uncensored/Qwen3.8-27B-Uncensored-Q4_K_M.gguf --ngl 15 \
  --mmproj /app/models/qwen-27b-uncensored/mmproj-Qwen3.8-27B-Uncensored-f16.gguf

# Get help and see all available parameters
./run-cpu-gui.sh --help
./run-gpu-gui.sh --help

# List downloaded models from the llama directory
find ../models/gguf -name '*.gguf'
```

Both scripts serve a chat UI at `http://localhost:9000`, with temperature, sampling and system-prompt controls. Set the model, GPU layers and vision projector through the launcher arguments shown above. Multiple clients can connect; actual concurrency depends on the server configuration.

Copy a template from `system-prompts/` into the web UI:

- `generic.txt`: general assistant
- `coding.txt`: coding and debugging
- `creative.txt`: creative writing
- `technical.txt`: documentation and system administration
- `anarchist.txt`: anarchist persona

llama.cpp validates the selected model and provides its own `--help`. GPU acceleration requires Docker with NVIDIA Container Runtime installed. Sharing GGUF storage does not make an old engine image support a newer model architecture; use an image compatible with the selected model.

### Strata (port 8080, opt-in)

Strata runs Flash-Next for offline chat, coding and reasoning. Select Q2_0, IQ2_XS, IQ3_S or the tested Uncensored Q4_K_S preset. These are different weight sets or quantizations for Strata's supported architecture, not arbitrary GGUF models. Its default browser UI is `http://127.0.0.1:8080`, with an OpenAI-compatible API at `/v1`.

Run `./strata/run.sh --list-models`, then choose with `./strata/run.sh --model qwen-iq2-xs`. First setup downloads only the selected model and builds its runtime. Later runs reuse the saved choice. The lower-precision presets target 48 or 64 GB RAM machines with a 12 GB NVIDIA GPU; the uncensored Q4 preset targets 128 GB RAM and 16 GB VRAM. See [Strata models, limits and offline copying](strata/README.offgrid.md) for requirements, Hugging Face access and existing-GGUF reuse.

New runtime files go in `strata/runtime/`; an existing installation directly in `strata/` is reused. GGUF weights are shared with llama.cpp under `models/gguf/qwen-flash-next-uncensored-q4_k_s/` and mounted read-only at `/models`.

```bash
# From the repository root, start only Strata
./strata/run.sh

# Stop only Strata
docker compose stop strata

# Follow its model-loading progress
docker compose logs -f --tail 50 strata
```

Normal `docker compose up` skips Strata. Start it explicitly with the launcher; it does not restart automatically. Smaller presets default to 32K context; the tested uncensored Q4 defaults to 256K, an 88 GiB RAM cap and 10 CPUs. Context, RAM, expert budget, CPU quota, VRAM reserve and port are configurable. Concurrent clients queue. Vision is disabled. Avoid running another large model alongside it.

Build and archive the local image while online, then load it on the offline machine:

```bash
./save-docker-images.sh --build-strata
./load-docker-images.sh --strata-only
```

The archive is `docker-images/qwen-strata-local_fb58e0d.tar`, with a SHA256 sidecar checked before loading. `--strata-only` on the save script exports the existing image, building only if missing. The previous archive stays as `.tar.previous`. Copy the installed runtime and `models/gguf/` too, preserving permissions and symlinks. After loading the archive, `./strata/run.sh --offline` starts without builds or downloads. Other GPU architectures may require an engine rebuild.

Tested on 128 GB RAM and a 16 GB RTX A5000 Laptop GPU. Tool calls and structured JSON passed a small test suite. Retrieval passed at about 250K input tokens; long-document reasoning was not evaluated.

For other hardware or models, follow [Strata's setup guide](https://github.com/Niko1221/Strata/blob/fb58e0dbc8399662c0e47c76578c6e878b14f6cf/docs/AI_SETUP.md) and [model guide](https://github.com/Niko1221/Strata/blob/fb58e0dbc8399662c0e47c76578c6e878b14f6cf/docs/MODELS.md). Each model needs a supported quantization and a pack built from its exact weights. A fresh clone includes the launcher and setup files, not the downloaded runtime, image or weights.

In Open WebUI, add an [OpenAI-compatible connection](https://docs.openwebui.com/getting-started/quick-start/connect-a-provider/starting-with-openai-compatible/) to `http://strata:8080/v1`. This is the address inside the Compose network; host clients use `http://127.0.0.1:8080/v1`. The connection is not added automatically. Ollama Chat Party only uses Ollama's API. Strata has no API key configured here, so keep its published port on localhost.

### AI compatibility and updates

Strata **0.1.41**, source `fb58e0dbc8399662c0e47c76578c6e878b14f6cf`, passed the local Q4_K_S tests. [0.1.45](https://github.com/Niko1221/Strata/releases/tag/v0.1.45) is available upstream but has not been tested with this installation.

The archived llama.cpp CPU server is **build 6123**, commit `79c1160b`. It rejects the downloaded 27B with `unknown model architecture: 'qwen35'`. Replace the old llama images with builds supporting the selected Qwen architecture before using the examples above. Test text generation and, if needed, the vision projector before saving the replacement images offline.

The launchers do not pull updates. Loading an old image archive restores the old build, even if its tag says `latest` or `main`. Keep the previous image and a data backup when testing replacements; update the offline archive after the replacement passes.

## Preparing for the apocalypse

Download the content and software you want to keep offline. Check available disk space first.

### Download everything

```bash
# Download everything at once (Docker images, APKs, packages, ISOs, ZIM archives)
./trigger-downloads.sh
```

### Docker images

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

It also saves the local Strata image when the image or installation is present. Strata builds locally; the script never pulls that image from a registry. Use `--build-strata` to rebuild and save only Strata, or `--strata-only` to save its existing image. Loading all archives also verifies and loads Strata. These operations do not start the service. Build, save and load require Docker, Bash, `jq`, `sha256sum` and `flock`.

### Linux packages

Install the toolkit on Ubuntu/Debian:

```bash
cd apps/linux/deb

# Install the toolkit
./install.sh
```

The script sets up repositories and installs Docker, development tools, SDR software, security tools and virtualization packages.

See [apps/linux/deb/README.md](apps/linux/deb/README.md) for detailed package descriptions and use cases.

### Offgrid Ubuntu virtual machine

Download a pre-configured Ubuntu VM with all packages already installed:

```bash
cd ubuntu

# Download VM in your preferred format
./get-qcow2.sh    # For QEMU/KVM
./get-vdi.sh      # For VirtualBox
./get-vhdx.sh     # For Hyper-V

# Run with QEMU (16GB RAM, 8 cores)
./run-qcow2.sh
```

VM details:

- OS: Ubuntu with XFCE desktop
- User: `offgrid`, password: `offgrid`
- Packages: about 280 toolkit packages pre-installed

### Android apps

Download APKs and install them over USB:

```bash
cd apps/android/apk

# Download the APK collection
./download.sh

# Install them via ADB when needed
./install.sh
```

Apps included:

- Kiwix: reads ZIM archives, including offline Wikipedia.
- F-Droid: open-source app catalog and installer.
- Termux: terminal environment with programming languages and command-line tools.
- VLC: plays local audio and video.
- Organic Maps: offline OpenStreetMap navigation, also available as a Linux Flatpak.
- Briar Messenger: encrypted messaging, including local Bluetooth and Wi-Fi connections.
- Briar Mailbox: stores encrypted Briar messages for offline recipients.
- BitChat: Bluetooth mesh messaging.
- KeePassDX: local encrypted password databases.
- SDR++: software-defined radio receiver.

### Bootable images

Download operating systems and recovery tools for bootable USB drives:

```bash
cd apps/iso

# Download the ISO collection
./download.sh

# Create bootable USB drives
sudo ./install.sh
```

ISOs included:

- Ventoy Live CD: creates USB drives that boot multiple ISOs.
- Xubuntu 24.04.2: Ubuntu with XFCE.
- Lubuntu 24.04.2: Ubuntu with LXQt.
- Kali Linux 2025.2: security testing and forensics tools.
- Tiny11 23H2: reduced Windows 11 build.
- TinyCore Linux CorePlus: modular Linux with desktop choices and wireless support.
- DragonOS Noble R5: Ubuntu-based SDR system with GNU Radio and GQRX.
- SkyWave Linux 5.7.0: amateur radio, SDR and electronics tools.
- GParted Live: disk partitioning and recovery tools.

### Web content archives

#### Download existing archives

Browse [the Kiwix library](https://library.kiwix.org/) and put downloaded ZIM files in `zim/data/`.

#### Download the archive collection

```bash
cd zim

# Download development and preparedness content
./download.sh
```

Archives included:

- FreeCodeCamp: coding tutorials
- Termux documentation: Android terminal reference
- Military Medicine: emergency and combat medicine
- Programming documentation: C++, Go, Docker, JavaScript, C, CSS, HTML, Nginx and Linux man pages
- Mankier: Linux manual pages
- Open Data Structures: algorithms and data structures textbook
- Simple Wikipedia: articles in basic English
- Ham Radio Stack Exchange: amateur radio Q&A
- Open Music Theory: music theory reference
- Based Cooking: recipes
- Food Preparation Guide: preparation and preservation
- SigID Wiki: radio signal identification
- Learn X in Y Minutes: language tutorials and cheat sheets
- Ready State: emergency preparedness
- GNU Radio Wiki: documentation and tutorials
- Go.dev: Go documentation
- Linux Command: command-line tutorials and reference
- TruePrepper: preparedness guides
- Linux Journey: Linux tutorials
- RTL-SDR: news, tutorials and projects

#### Create custom archives

```bash
# Archive any website for offline use (auto-generates name)
./zim/create.sh https://stackoverflow.com
# Creates: stackoverflow.com.zim

# Archive with custom name
./zim/create.sh https://stackoverflow.com stackoverflow

# Archive website with path (auto-generates descriptive name)
./zim/create.sh https://example.com/docs/guide
# Creates: example.com_docs_guide.zim

# Copy ZIM files to Android devices
./zim/copy-to-android.sh data/stackoverflow.com.zim
```

Open the resulting ZIM files in Kiwix. Check that the pages you need were captured before going offline.

### Offline maps

Download map data for Organic Maps:

```bash
cd maps

# List all available maps
./maps.sh list

# Search for specific regions
./maps.sh list romania
./maps.sh list united

# Download maps (downloads to maps/data/)
./maps.sh list romania | ./maps.sh download
```

Map files (.mwm format) are automatically downloaded to `maps/data/` and can be transferred to Android devices or used with the Linux Flatpak version of Organic Maps.

## Running the stack

```bash
# Start the default services, excluding opt-in Strata
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

## Ports and access

Once running, access services at:

- [Kiwix](http://localhost:8000)
- [Open WebUI](http://localhost:8001)
- [Ollama Chat Party](http://localhost:8002)
- [TheLounge](http://localhost:8003)
- [Icecast](http://localhost:8004)
- [File server](http://localhost:8005)
- [Strata chat](http://127.0.0.1:8080), only when explicitly started

Default credentials:

- Open WebUI: Create your own admin account on first visit
- IRC operator: `offgrid` / `offgrid123`
- Ollama Chat Party: password is `offgrid123`
- Icecast: all passwords are `offgrid123`
- File Server: `offgrid` / `offgrid123` (can be changed with FILE_SERVER_AUTH env var)

## Data and storage

All important data persists in these directories:

```
ollama/data/          # AI models and SSH keys
openwebui/data/       # Chat history and settings
models/gguf/          # Shared GGUF weights for llama.cpp and Strata
strata/               # Local Strata runtime, packs, MTP and evaluation results
llama/system-prompts/ # System prompt templates for AI personalities
zim/data/             # Offline web archives
apps/android/apk/data/    # Downloaded APK files
apps/iso/data/           # Downloaded ISO images
docker-images/           # Saved Docker images and checksums
file-server/other-files/ # Custom files for web download
```

Most data is gitignored. Back up these directories separately from the repository.

## Troubleshooting

**"Docker not found"**

- Install Docker and its Compose plugin.

**"No devices connected" (Android stuff)**

- Enable USB debugging on your phone
- Connect via USB and accept the prompt

**"AI models are slow as shit"**

- Check available RAM and VRAM. Use a smaller model or quantization if the selected model does not fit.
- Download Ollama models before going offline. Strata and llama.cpp need their weights in place before starting.

**"No GPU"**

- Remove Ollama's GPU device reservation from `docker-compose.yml` to run it on CPU. The current Strata installation requires an NVIDIA GPU.

**"Can't connect to IRC"**

- Make sure InspIRCd container is running
- Try `docker-compose logs inspircd`

**"I broke everything"**

- Check `docker-compose logs` for the failing service before changing anything.
- Keep a data backup. Deleting a data directory also deletes the models, conversations or other files stored there.

## License

WTFPL - Do What The Fuck You Want To Public License. See [LICENSE](LICENSE) file.
