# Project file structure

Clean layout for the AI Chat Application. **Source code** lives under `lib/` and `backend/app/`. Everything else is platform config, tooling, or generated output.

```
Chat-Application/
│
├── lib/                          # Flutter app (Dart source)
│   ├── main.dart                 # App entry
│   ├── app.dart                  # MaterialApp, providers, routes
│   ├── core/theme/               # Colors, themes, accent extension
│   ├── l10n/                     # UI strings (en, es, fr, de, hi)
│   ├── models/                   # Message, session, wallpaper, etc.
│   ├── providers/                # State: chat, theme, locale, accent
│   ├── screens/
│   │   ├── ai_chat_screen.dart   # Main chat UI
│   │   ├── settings_screen.dart  # Backend URL, knowledge, theme
│   │   └── chat_history_screen.dart
│   ├── services/
│   │   ├── ai_backend_service.dart   # HTTP → FastAPI
│   │   ├── api_config_service.dart   # Saved backend URL
│   │   ├── chat_history_service.dart
│   │   ├── attachment_service.dart
│   │   ├── export_chat_service.dart
│   │   └── voice_input_service.dart
│   └── widgets/                  # Bubbles, input bar, chips, glass UI
│
├── backend/                      # Python API
│   ├── run.py                    # Start: python run.py
│   ├── requirements.txt
│   ├── Dockerfile                # Cloud deploy
│   ├── .env.example              # Copy → .env (add HF token)
│   ├── .env                      # Local secrets (not in git)
│   ├── app/
│   │   ├── main.py               # FastAPI + startup
│   │   ├── config.py             # Settings from .env
│   │   ├── schemas.py            # Request/response models
│   │   ├── api/routes.py         # /api/chat, /health, /knowledge
│   │   ├── graph/
│   │   │   ├── agent.py          # LangGraph retrieve → generate
│   │   │   ├── query_utils.py    # Small-talk, RAG helpers
│   │   │   └── state.py
│   │   └── services/
│   │       ├── chroma_service.py      # Vector DB / RAG
│   │       └── huggingface_service.py # Embeddings + chat
│   ├── tests/
│   │   └── test_sanitize_output.py
│   ├── venv/                     # Generated (pip install) — gitignored
│   └── chroma_data/              # Vector index — gitignored
│
├── test/                         # Flutter unit tests
│   └── widget_test.dart
│
├── android/                      # Flutter Android project
├── ios/                          # Flutter iOS project
├── web/                          # Flutter web
├── windows/                      # Flutter Windows desktop
│
├── .github/workflows/            # CI (e.g. deploy web)
│
├── pubspec.yaml                  # Flutter dependencies
├── pubspec.lock
├── analysis_options.yaml
├── README.md                     # Overview, HR demo, how to run
├── DEPLOY.md                     # Render / hosting
├── PROJECT_STRUCTURE.md          # This file
├── render.yaml                   # Render blueprint
└── LICENSE
```

## Generated / local only (safe to delete; recreated on build)

| Path | Recreated by |
|------|----------------|
| `build/` | `flutter build` / `flutter run` |
| `.dart_tool/` | `flutter pub get` |
| `backend/venv/` | `pip install -r requirements.txt` |
| `backend/chroma_data/` | Server startup + seed / reindex |
| `.flutter-plugins-dependencies` | `flutter pub get` |

## Removed as unnecessary

- Root `venv/` (wrong place; use `backend/venv/` only)
- `.idea/`, `*.iml` (IDE settings)
- Unused widgets: `feature_highlight_card.dart`, `animated_gradient_background.dart`

## Do not delete

- `backend/.env` — your Hugging Face API key
- `lib/`, `backend/app/` — application source
- `android/`, `ios/`, `web/`, `windows/` — required for Flutter targets
