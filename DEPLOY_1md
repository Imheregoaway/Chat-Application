# Easiest deploy  (≈30 minutes)

Two public links:

1. **Chat app** (what HR opens in the browser)  
2. **API** (runs in the background on Render)

---

## Before you start

- [ ] Code pushed to GitHub: https://github.com/Imheregoaway/chat-application  
- [ ] Hugging Face token: https://huggingface.co/settings/tokens  
- [ ] Flutter installed on your PC (`flutter doctor`)

---

## Part 1 — Backend on Render (free)

1. Open **https://render.com** → sign in with **GitHub**.
2. **New +** → **Blueprint** → select repo **`chat-application`**.
3. Render reads `render.yaml` and creates service **`ai-chat-api`**.
4. When asked for env vars, set:
   - **`HUGGINGFACE_API_KEY`** = `hf_...` (your token)
5. Click **Deploy** and wait until status is **Live** (5–10 min first time).
6. Copy your URL, e.g. `https://ai-chat-api-xxxx.onrender.com`
7. Test in browser:  
   `https://YOUR-URL.onrender.com/api/health`  
   → should show `"huggingface_configured": true`

**HR demo tip:** Free tier **sleeps** after ~15 min idle. **1 minute before the meeting**, open the health URL so the API wakes up (first chat may take 30–60 s).

---

## Part 2 — Web app (easiest: Netlify)

### Build on your PC

Replace `YOUR-URL` with your real Render URL (no trailing slash):

```powershell
cd c:\Work\Project\Chat-Application
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://YOUR-URL.onrender.com
```

Output folder: `build\web\`

### Upload to Netlify (drag & drop)

1. Go to **https://app.netlify.com** → sign up (free).
2. **Add new site** → **Deploy manually**.
3. Drag the folder **`build\web`** onto the page.
4. Netlify gives you a link, e.g. `https://something-random.netlify.app`  
   → **This is the link you send to HR.**

Optional: **Site settings → Domain management → Rename** to something like `your-name-ai-chat.netlify.app`.

---

## Part 3 — 2-minute test before HR

1. Open your **Netlify** link.
2. Wait for the chat screen (if slow, API may be waking).
3. Ask: **how to make pasta** → should get a real answer (not demo mode).
4. Optional: **Settings → Add Knowledge** → paste a short company note → index → ask about it.

---

## What to share with HR

| Link | Purpose |
|------|---------|
| `https://your-app.netlify.app` | **Main demo** — open this |
| `https://your-api.onrender.com/api/health` | Only if they ask “is the server up?” |

**Do not share** your Hugging Face token or `backend/.env`.

---

## Even faster (same day, no cloud UI)

If you only need a **15-minute screen share** and HR is on the call:

1. Run backend + Flutter on your laptop (see README).
2. Use **https://ngrok.com** to expose port 8000, or show via **screen share** only.

Cloud deploy (above) is better when HR must open a link **on their own phone/laptop later**.

---

## Alternative: GitHub Pages (automatic on push)

If you prefer one repo for everything:

1. GitHub repo → **Settings → Secrets → Actions** → add secret **`API_BASE_URL`** = your Render URL.
2. **Settings → Pages → Source** = **GitHub Actions**.
3. Push to `main` — workflow deploys web.

Your site: **`https://imheregoaway.github.io/chat-application/`**

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Demo mode message | Set `HUGGINGFACE_API_KEY` on Render; redeploy |
| Backend offline in app | Rebuild web with correct `--dart-define=API_BASE_URL=...` |
| Very slow first message | Render waking up — open `/api/health` first |
| CORS error | API URL must start with `https://` |

---

## Checklist on demo day

- [ ] Render health URL opened 1 min early  
- [ ] Netlify link opens on phone (test once)  
- [ ] Sample question works  
- [ ] Optional knowledge snippet added in Settings  
