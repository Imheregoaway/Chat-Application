import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router
from app.config import get_settings
from app.services.chroma_service import ChromaService
from app.services.huggingface_service import HuggingFaceService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="AI Chat API",
    description="LangGraph + ChromaDB + Hugging Face AI chat backend",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.on_event("startup")
def startup():
    get_settings.cache_clear()
    settings = get_settings()
    hf = HuggingFaceService()
    chroma = ChromaService(hf)
    seeded = chroma.ensure_core_knowledge()
    reindexed = 0
    if hf.is_configured:
        if chroma.embeddings_need_reindex():
            reindexed = chroma.reindex_all()
        added = chroma.ensure_core_knowledge()
        if added:
            logger.info("Added %s seed documents to ChromaDB", added)
    logger.info("API ready on %s:%s", settings.api_host, settings.api_port)
    logger.info("Hugging Face configured: %s", hf.is_configured)
    logger.info(
        "ChromaDB documents: %s (seeded %s, reindexed %s)",
        chroma.count(),
        seeded,
        reindexed,
    )


@app.get("/")
def root():
    return {
        "name": "AI Chat API",
        "docs": "/docs",
        "health": "/api/health",
    }
