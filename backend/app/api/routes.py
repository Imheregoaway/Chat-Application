from fastapi import APIRouter, HTTPException

from app.config import get_settings
from app.graph.agent import run_agent
from app.schemas import (
    ChatRequest,
    ChatResponse,
    HealthResponse,
    KnowledgeRequest,
    KnowledgeResponse,
)
from app.services.chroma_service import ChromaService
from app.services.huggingface_service import HuggingFaceService

router = APIRouter(prefix="/api")


def _hf() -> HuggingFaceService:
    return HuggingFaceService()


def _chroma() -> ChromaService:
    return ChromaService(_hf())


@router.get("/health", response_model=HealthResponse)
def health():
    settings = get_settings()
    chroma = _chroma()
    return HealthResponse(
        status="ok",
        huggingface_configured=_hf().is_configured,
        chroma_documents=chroma.count(),
        chat_model=settings.hf_chat_model,
        embedding_model=settings.hf_embedding_model,
        inference_provider=settings.hf_provider,
    )


@router.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest):
    try:
        history = [{"role": m.role, "content": m.content} for m in request.history]
        result = run_agent(
            request.message,
            history=history,
            locale=request.locale,
            attachments=request.attachments,
        )
        context = result.get("context", "")
        sources = len([line for line in context.split("\n") if line.strip()]) if context else 0
        return ChatResponse(
            response=result["response"],
            context_used=context,
            sources_count=sources,
            no_knowledge=bool(result.get("no_knowledge", False)),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e


@router.post("/knowledge", response_model=KnowledgeResponse)
def add_knowledge(request: KnowledgeRequest):
    try:
        doc_id = _chroma().add_document(
            request.text,
            metadata={"source": request.source},
        )
        return KnowledgeResponse(
            id=doc_id,
            message="Document indexed in ChromaDB",
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e


@router.post("/knowledge/seed")
def seed_knowledge():
    chroma = _chroma()
    count = chroma.ensure_core_knowledge()
    return {"seeded": count, "total": chroma.count()}


@router.post("/knowledge/reindex")
def reindex_knowledge():
    """Rebuild all ChromaDB embeddings (fixes demo-mode index after adding HF token)."""
    hf = _hf()
    if not hf.is_configured:
        raise HTTPException(
            status_code=400,
            detail="Set HUGGINGFACE_API_KEY in backend/.env before reindexing",
        )
    chroma = _chroma()
    count = chroma.reindex_all()
    return {"reindexed": count, "total": chroma.count()}
