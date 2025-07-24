# Ollama Chat Party - RAG Engine

This directory contains data and configuration for the ollama-chat-party RAG engine.

## Directory Structure

- `data/` - Documents for RAG (Retrieval-Augmented Generation) indexing

## Usage

The RAG engine is accessible at: http://localhost:8000

- Password: `offgrid123`

## Adding Documents for RAG

Place documents you want to include in RAG searches in the `rag-docs/` directory:

```bash
# Add documents to be indexed
cp /path/to/your/documents/* ./ollama-chat-party/rag-docs/

# Restart the service to reindex
docker-compose restart ollama-chat-party
```

## Supported Document Types

📄 Text files (.txt, .md)
🌐 Web content (.html, .htm)
📋 PDFs
📝 Word docs (.docx)
📊 LibreOffice (.odt)

## Configuration

The service is configured to:

- Connect to the local Ollama instance at `http://ollama:11434`
- Listen on all interfaces at port 8000
- Use `/documents` as the document directory for indexing
