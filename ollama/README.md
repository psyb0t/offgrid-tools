# Ollama Models Directory

This directory stores Ollama models and configuration for offline AI capabilities.

## Quick Start

**Prerequisites:** 
- NVIDIA GPU with Docker GPU support (nvidia-container-toolkit)
- Run: `nvidia-smi` to verify GPU access

1. Start the Ollama server with GPU acceleration:
   ```bash
   docker-compose up ollama
   ```

2. Pull models (requires internet):
   ```bash
   # Pull a small model for testing
   docker exec ollama-server ollama pull llama3.2:1b
   
   # Pull more capable models
   docker exec ollama-server ollama pull llama3.2:3b
   docker exec ollama-server ollama pull qwen2.5:0.5b
   docker exec ollama-server ollama pull codellama:7b
   ```

3. Test the API:
   ```bash
   curl http://localhost:11434/api/generate -d '{
     "model": "llama3.2:1b",
     "prompt": "Why is the sky blue?",
     "stream": false
   }'
   ```

## API Access

The Ollama API is exposed on port **11434** and accessible at:
- **API endpoint**: http://localhost:11434
- **Models list**: http://localhost:11434/api/tags
- **Health check**: http://localhost:11434/api/version

## Compatible UIs

You can connect any Ollama-compatible UI to http://localhost:11434:

- **Open WebUI** (formerly Ollama WebUI)
- **Chatbot UI**
- **AnythingLLM**
- **LibreChat**
- **Continue.dev** (VS Code extension)

## Model Management

```bash
# List downloaded models
docker exec ollama-server ollama list

# Remove a model
docker exec ollama-server ollama rm llama3.2:1b

# Show model info
docker exec ollama-server ollama show llama3.2:1b
```

## Popular Models

| Model | Size | Use Case |
|-------|------|----------|
| `qwen2.5:0.5b` | ~400MB | Very fast, basic tasks |
| `llama3.2:1b` | ~1GB | Fast, good for chat |
| `llama3.2:3b` | ~2GB | Balanced performance |
| `codellama:7b` | ~4GB | Code generation |
| `mistral:7b` | ~4GB | General purpose |

## GPU Configuration

The service is configured to use all available NVIDIA GPUs for faster inference. Requirements:
- NVIDIA GPU drivers installed
- Docker with GPU support (nvidia-container-toolkit)
- Verify with: `docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi`

## Storage

Models are stored in `./ollama/data/` which maps to `/root/.ollama` inside the container. This ensures:
- Models persist between container restarts
- Models are available offline after initial download
- Easy backup and transfer of models

## Directory Structure

```
ollama/
├── README.md          # This file
└── data/             # Ollama models and configuration
    ├── models/       # Downloaded AI models
    ├── logs/
    └── ...
```

## Performance

With GPU acceleration:
- **llama3.2:1b** - ~100+ tokens/sec
- **llama3.2:3b** - ~50+ tokens/sec  
- **codellama:7b** - ~20+ tokens/sec

Without GPU (CPU only):
- Significantly slower, use smaller models like qwen2.5:0.5b