# AI Chat Application

An AI chat app powered by **LangGraph**, **ChromaDB**, and the **Hugging Face Inference API**, with a Flutter front-end.

```
Flutter UI  →  FastAPI Backend  →  LangGraph Agent
                                    ├── ChromaDB (vector RAG)
                                    └── Hugging Face (embeddings + chat)
```

## Architecture

| Layer | Tech | Role |
|-------|------|------|
| Front-end | Flutter | Chat UI, settings, knowledge upload |
| API | FastAPI | REST endpoints |
| Orchestration | **LangGraph** | `retrieve` → `generate` pipeline |
| Vector DB | **ChromaDB** | Semantic search / RAG context |
| Models | **Hugging Face API** | Embeddings + chat completion |

### LangGraph flow

```
User message
    ↓
[retrieve]  Query ChromaDB with HF embeddings
    ↓
[generate]  HF chat model + retrieved context
    ↓
Response
```

## Quick start

### 1. Backend (Python)

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt
copy .env.example .env   # Windows
# cp .env.example .env    # macOS/Linux
```

Edit `backend/.env` and set your [Hugging Face token](https://huggingface.co/settings/tokens):

```
HUGGINGFACE_API_KEY=hf_xxxxxxxx
```

Start the API:

```bash
python run.py
```

API docs: http://127.0.0.1:8000/docs

### 2. Flutter app

```bash
flutter pub get
flutter run
```

Default backend URL: `http://127.0.0.1:8000` (change in Settings if needed).

**Android emulator:** use `http://10.0.2.2:8000`  
**Physical device:** use your PC's LAN IP, e.g. `http://192.168.1.10:8000`

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Backend status, model info |
| POST | `/api/chat` | Chat via LangGraph pipeline |
| POST | `/api/knowledge` | Add text to ChromaDB |
| POST | `/api/knowledge/seed` | Seed default knowledge |

### Chat request example

```json
POST /api/chat
{
  "message": "What is LangGraph?",
  "history": [
    {"role": "user", "content": "Hi"},
    {"role": "assistant", "content": "Hello!"}
  ]
}
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `HUGGINGFACE_API_KEY` | — | Required for full LLM responses |
| `HF_CHAT_MODEL` | `HuggingFaceH4/zephyr-7b-beta` | Chat model |
| `HF_EMBEDDING_MODEL` | `sentence-transformers/all-MiniLM-L6-v2` | Embeddings |
| `CHROMA_PERSIST_DIR` | `./chroma_data` | Vector store path |
| `RAG_TOP_K` | `4` | Documents retrieved per query |

Without `HUGGINGFACE_API_KEY`, the backend runs in **demo mode** (fallback embeddings + placeholder replies).

## Project structure

```
backend/
  app/
    main.py                 # FastAPI entry
    api/routes.py           # REST endpoints
    graph/agent.py          # LangGraph workflow
    services/
      chroma_service.py     # ChromaDB
      huggingface_service.py
  requirements.txt
  run.py

lib/                        # Flutter UI
  app.dart
  screens/
    ai_chat_screen.dart
    settings_screen.dart
  services/
    ai_backend_service.dart
    api_config_service.dart
  widgets/
    ai_message_bubble.dart
    ...
```

## Add your own knowledge

1. Open **Settings** in the app
2. Paste text under **Add Knowledge**
3. Tap **Index in ChromaDB**
4. Ask questions — LangGraph will retrieve relevant chunks automatically

## Run 24/7 with a public link

See **[DEPLOY.md](DEPLOY.md)** — deploy the API to Render (or similar) and Flutter web to GitHub Pages / Netlify so anyone can open a URL anytime.

## Host on GitHub

### What is **not** uploaded (kept local)

- `backend/.env` — your Hugging Face API key
- `backend/venv/` — Python virtual environment
- `backend/chroma_data/` — vector DB files
- `build/` — Flutter build output

Clone the repo and copy `backend/.env.example` → `backend/.env` on each machine.

### Push this project to GitHub

**1. Initialize git** (once, in the project folder):

```powershell
cd c:\Work\Project\Chat-Application
git init
git add .
git commit -m "Initial commit: AI chat app with LangGraph, ChromaDB, and Flutter UI"
```

**2. Create a new repository** on [github.com/new](https://github.com/new):

- Name: e.g. `Chat-Application` or `ai-chat-langgraph`
- **Do not** add README, .gitignore, or license (this repo already has them)

**3. Connect and push:**

```powershell
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your GitHub user and repo name.

**Using GitHub CLI** (if `gh` is installed and logged in):

```powershell
gh repo create YOUR_REPO_NAME --public --source=. --remote=origin --push
```

### After cloning on another PC

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
# Backend
cd backend && python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
# Edit .env with your HUGGINGFACE_API_KEY
python run.py
# Flutter (new terminal, repo root)
flutter pub get && flutter run
```

## License

MIT
