# 🔥 offgrid-tools 🔥

fuck the grid 🖕 Docker Compose setup for when the internet dies and you still need to get shit done.

## 📦 what's in the box

- `docker-compose.yml` - your entire digital survival kit 🛠️
- `save-docker-images.sh` / `load-docker-images.sh` - smuggle containers like digital contraband 🏴‍☠️
- service dirs with data folders for when you need to hoard information 💾

## 🚀 the stack

- **Kiwix** 📚 - offline knowledge server (supports wikipedia, stackoverflow, gutenberg, wiktionary, whatever .zim files you throw at it)
- **Ollama** 🤖 - AI that runs on your hardware, not in some corpo datacenter
- **Open WebUI** 💬 - talk to your AI without sending chat logs to surveillance capitalism

## 🎯 getting started

clone this repo, run `docker-compose up`, become ungovernable 😈

## 🌐 where to find your shit

- **Kiwix** 📚 - `http://localhost:8080` - whatever knowledge you dumped in there
- **Open WebUI** 💬 - `http://localhost:3000` - AI chat interface  
- **Ollama API** 🤖 - `http://localhost:11434` - raw AI endpoint

## 📋 what the fuck is this anyway

this is a self-contained digital bunker for when shit hits the fan. internet goes down? government censors your access? ISP decides to fuck with you? doesn't matter. this stack runs entirely on your local machine.

**Kiwix** 📚 serves up compressed knowledge archives (.zim files). download wikipedia, stack overflow, project gutenberg, medical texts, survival guides, whatever. all searchable offline. it's like having the library of alexandria on your laptop but without the fire risk.

**Ollama** 🤖 is your local AI that doesn't phone home. runs llama, mistral, code models, whatever. no api keys, no monthly subscriptions, no sending your private thoughts to openai's data mining operation. just raw silicon doing math for you.

**Open WebUI** 💬 gives you a chatgpt-like interface that talks to your local ollama instance. upload documents, ask questions, generate code, whatever. all stays on your hardware.

the beauty is everything talks to everything else through docker's internal network. no external dependencies once it's running. 

## 🏴‍☠️ getting .zim files

- official kiwix library: `download.kiwix.org/zim/`
- wikipedia dumps: grab the latest from their torrents
- stack overflow: because you'll need to debug shit offline too
- medical references: for when webmd isn't available
- whatever else you can find in .zim format

throw them in `./zim/data/` and kiwix will serve them all up.

## 🤖 getting AI models

once ollama is running:
```bash
docker exec -it offgrid-tools-ollama-1 ollama pull llama3.2:1b
docker exec -it offgrid-tools-ollama-1 ollama pull codellama
docker exec -it offgrid-tools-ollama-1 ollama pull mistral
```

smaller models run on potato hardware. bigger models need decent gpu/ram.

## 💾 data persistence

everything important lives in these folders:
- `./zim/data/` - your knowledge archives
- `./ollama/data/` - AI models and config  
- `./openwebui/data/` - chat history and settings

back these up. when the apocalypse comes you'll thank yourself.

no tracking 🚫 no telemetry 🚫 no bullshit 🚫 just tools that work when everything else fails 💀