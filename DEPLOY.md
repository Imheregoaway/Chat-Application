# Run your chat 24/7 with a public link

Running on your PC only works while the PC is on. For a **link anyone can open anytime**, host:

1. **Backend API** (Python) on a cloud server → `https://your-api.onrender.com`
2. **Chat UI** (Flutter web) on static hosting → `https://your-name.github.io/...`

---

## Architecture

```
Browser opens your GitHub Pages link
        ↓
Flutter web app (static files)
        ↓ HTTPS
Cloud API (Render / Railway / Fly.io)
        ↓
LangGraph + ChromaDB + Hugging Face
```

---

## Step 1 — Push code to GitHub

If not done yet, push your repo to GitHub (see README **Host on GitHub**).

---

## Step 2 — Deploy backend (API) on Render (free tier)

1. Go to [render.com](https://render.com) and sign in with GitHub.
2. **New** → **Blueprint** → select your repo.
3. Render reads `render.yaml` and creates **ai-chat-api**.
4. Add environment variable (required):
   - `HUGGINGFACE_API_KEY` = your token from https://huggingface.co/settings/tokens
5. Deploy. When finished, copy your URL, e.g.  
   `https://ai-chat-api-xxxx.onrender.com`
6. Test: open `https://YOUR-URL.onrender.com/api/health`

**Free tier note:** The API may **sleep after ~15 minutes** with no traffic. The first request after sleep can take 30–60 seconds to wake up. For always-on 24/7 without sleep, use a paid plan or another host (Railway, Fly.io, a VPS).

**ChromaDB on free tier:** Vector data may reset when the service redeploys unless you add a persistent disk (paid on Render).

---

## Step 3 — Build Flutter web for your API URL

Replace with your real Render URL:

```powershell
cd c:\Work\Project\Chat-Application
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://YOUR-URL.onrender.com
```

Output folder: `build\web\`

---

## Step 4 — Host the web UI (GitHub Pages)

### Option A — GitHub Pages for repo `Chat-application`

**Your chat link will be:**

`https://YOUR_GITHUB_USERNAME.github.io/Chat-application/`

**Manual build (Windows):**

```powershell
flutter build web --release ^
  --dart-define=API_BASE_URL=https://YOUR-URL.onrender.com ^
  --base-href /Chat-application/
```

**Automatic deploy (recommended):**

1. Deploy backend on Render first; copy API URL.
2. GitHub repo **Chat-application** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
   - Name: `API_BASE_URL`
   - Value: `https://your-api.onrender.com` (no trailing slash)
3. **Settings** → **Pages** → Source: **GitHub Actions**
4. Push to `main` — workflow `.github/workflows/deploy-web.yml` publishes the site.

### Option B — Netlify (easy drag-and-drop)

1. [netlify.com](https://netlify.com) → **Add site** → **Deploy manually**
2. Drag the `build/web` folder onto the page
3. You get a link like `https://random-name.netlify.app`

In the app **Settings**, users can still change the API URL if needed.

---

## Step 5 — Open your 24/7 chat link

Share the **Flutter web URL** (GitHub Pages or Netlify), not the Render `/docs` URL.

Users open the web link → app talks to your cloud API → LangGraph + ChromaDB + Hugging Face run on the server.

---

## Quick reference

| What | URL |
|------|-----|
| Chat for users | `https://you.github.io/Chat-Application/` |
| API health | `https://your-api.onrender.com/api/health` |
| API docs | `https://your-api.onrender.com/docs` |

---

## Other hosts

| Service | Backend | Web UI |
|---------|---------|--------|
| [Render](https://render.com) | `render.yaml` in repo | GitHub Pages / Netlify |
| [Railway](https://railway.app) | Deploy `backend/` with Dockerfile | Same |
| [Fly.io](https://fly.io) | `fly launch` in `backend/` | Same |
| VPS (DigitalOcean, etc.) | Docker + nginx | nginx serves `build/web` |

---

## Security

- Never commit `backend/.env` or API keys to GitHub.
- Set `HUGGINGFACE_API_KEY` only in the cloud dashboard (Render env vars).
- For production, consider rate limiting and restricting CORS to your web domain only.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| First request very slow | Render free tier waking from sleep |
| CORS error | Backend already allows `*`; ensure API URL uses `https://` |
| Backend offline in app | Wrong URL in build; rebuild with `--dart-define=API_BASE_URL=...` |
| 502 on Render | Check logs; confirm `HUGGINGFACE_API_KEY` is set |
