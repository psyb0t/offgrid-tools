# Open WebUI

A modern, user-friendly web interface for Ollama AI models with ChatGPT-like experience.

## Quick Start

1. Start both Ollama and Open WebUI:
   ```bash
   docker-compose up ollama openwebui
   # Or start everything:
   docker-compose up
   ```

2. Open your browser and go to: **http://localhost:3000**

3. Sign up for a new account (first user becomes admin)

4. Start chatting with your AI models!

## Features

- 🎨 **Modern ChatGPT-like interface**
- 💬 **Multiple conversation threads**
- 📁 **File upload support** (PDFs, images, documents)
- 🔄 **Model switching** during conversations
- 👥 **User management** and permissions
- 🎯 **Custom prompts** and templates
- 📊 **Conversation history**
- 🌙 **Dark/light themes**
- 📱 **Mobile responsive**

## Model Management

Open WebUI automatically detects models from your Ollama server:

1. Pull models in Ollama first:
   ```bash
   docker exec ollama-server ollama pull llama3.2:3b
   docker exec ollama-server ollama pull codellama:7b
   ```

2. Refresh the model list in Open WebUI interface

3. Switch between models using the dropdown in chat

## Configuration

The interface connects to Ollama at `http://ollama:11434` automatically.

### Data Persistence

- User accounts, conversations, and settings are stored in `./openwebui/data/`
- Data persists between container restarts
- Easy backup by copying the `./openwebui/data/` directory

## Directory Structure

```
openwebui/
├── README.md          # This file
└── data/             # User data, conversations, settings
    ├── uploads/
    ├── vector_db/
    └── ...
```

### Admin Features

The first user to sign up becomes the admin and can:
- Manage user accounts
- Configure system settings
- Control model access permissions
- Set up custom prompts and templates

## Usage Tips

### File Upload
- Upload PDFs, images, or documents to ask questions about them
- Supports RAG (Retrieval Augmented Generation) for document analysis

### Custom Prompts
- Create reusable prompt templates
- Share prompts with other users
- Import/export prompt collections

### Model Switching
- Different models for different tasks:
  - `llama3.2:1b` - Quick responses, simple tasks
  - `llama3.2:3b` - Balanced performance
  - `codellama:7b` - Code generation and debugging
  - `mistral:7b` - General purpose, creative writing

## API Access

Open WebUI also provides OpenAI-compatible API endpoints:
- **Base URL**: http://localhost:3000/ollama/v1
- **Compatible with OpenAI libraries and tools**

## Troubleshooting

### Can't connect to models
- Ensure Ollama service is running: `docker-compose ps`
- Check Ollama has models: `docker exec ollama-server ollama list`
- Verify network connectivity between containers

### Performance Issues
- Ensure GPU access is working for Ollama
- Use smaller models if running on CPU only
- Check system resources: RAM and GPU memory

## Ports

- **Open WebUI**: http://localhost:3000
- **Ollama API**: http://localhost:11434 (internal)
- **Kiwix**: http://localhost:8080 (separate service)