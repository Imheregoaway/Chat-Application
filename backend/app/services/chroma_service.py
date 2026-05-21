from __future__ import annotations

import logging
import uuid
from typing import Any

import chromadb
from chromadb.config import Settings as ChromaSettings

from app.config import get_settings
from app.services.huggingface_service import HuggingFaceService

logger = logging.getLogger(__name__)


class ChromaService:
    """ChromaDB vector store for RAG knowledge."""

    def __init__(self, hf: HuggingFaceService | None = None) -> None:
        settings = get_settings()
        self._hf = hf or HuggingFaceService()
        self._client = chromadb.PersistentClient(
            path=settings.chroma_persist_dir,
            settings=ChromaSettings(anonymized_telemetry=False),
        )
        self._collection = self._client.get_or_create_collection(
            name=settings.chroma_collection,
            metadata={"hnsw:space": "cosine"},
        )
        self._top_k = settings.rag_top_k
        self._max_distance = settings.rag_max_distance

    def add_document(self, text: str, metadata: dict[str, Any] | None = None) -> str:
        doc_id = str(uuid.uuid4())
        embedding = self._hf.embed(text)
        self._collection.add(
            ids=[doc_id],
            documents=[text],
            embeddings=[embedding],
            metadatas=[metadata or {}],
        )
        return doc_id

    def search(self, query: str, top_k: int | None = None) -> list[dict[str, Any]]:
        k = top_k or self._top_k
        embedding = self._hf.embed(query)
        try:
            results = self._collection.query(
                query_embeddings=[embedding],
                n_results=k,
                include=["documents", "metadatas", "distances"],
            )
        except Exception as e:
            logger.warning("Chroma query failed: %s", e)
            return []

        hits: list[dict[str, Any]] = []
        docs = results.get("documents", [[]])[0]
        metas = results.get("metadatas", [[]])[0]
        distances = results.get("distances", [[]])[0]

        for doc, meta, dist in zip(docs, metas, distances):
            if doc:
                hits.append({
                    "text": doc,
                    "metadata": meta or {},
                    "distance": dist,
                })
        return hits

    def build_context(self, query: str) -> str:
        hits = self.search(query)
        if not hits:
            return ""
        parts = []
        for hit in hits:
            dist = hit.get("distance")
            if dist is not None and dist > self._max_distance:
                continue
            parts.append(hit["text"])
        if not parts:
            return ""
        return "\n".join(f"{i}. {t}" for i, t in enumerate(parts, 1))

    def count(self) -> int:
        return self._collection.count()

    def seed_defaults(self) -> int:
        if self.count() > 0:
            return 0

        defaults = [
            "This AI chat app uses LangGraph to orchestrate retrieve-then-generate workflows.",
            "ChromaDB stores document embeddings for semantic search and RAG.",
            "Hugging Face Inference API provides chat and embedding models.",
            "Add your own knowledge via POST /api/knowledge to improve answers.",
        ]
        for text in defaults:
            self.add_document(text, {"source": "seed"})
        return len(defaults)
