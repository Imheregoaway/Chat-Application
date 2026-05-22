from __future__ import annotations

import logging
import uuid
from typing import Any

import chromadb
from chromadb.config import Settings as ChromaSettings

from app.config import get_settings
from app.services.huggingface_service import HuggingFaceService

logger = logging.getLogger(__name__)

# Documents indexed without HF (hash embeddings) never match HF query vectors.
_STALE_PROBE_QUERY = "LangGraph retrieve generate ChromaDB RAG"
_STALE_DISTANCE = 0.85


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

    @property
    def max_distance(self) -> float:
        return self._max_distance

    def add_document(self, text: str, metadata: dict[str, Any] | None = None) -> str:
        doc_id = str(uuid.uuid4())
        embedding = self._hf.embed(text)
        meta = dict(metadata or {})
        meta.setdefault("embedding", "huggingface" if self._hf.is_configured else "fallback")
        self._collection.add(
            ids=[doc_id],
            documents=[text],
            embeddings=[embedding],
            metadatas=[meta],
        )
        return doc_id

    def embeddings_need_reindex(self) -> bool:
        """True when stored vectors were likely built with fallback (demo) embeddings."""
        if self.count() == 0:
            return False
        if not self._hf.is_configured:
            return False
        hits = self.search(_STALE_PROBE_QUERY, top_k=1)
        if not hits:
            return True
        dist = hits[0].get("distance")
        return dist is None or dist > _STALE_DISTANCE

    def reindex_all(self) -> int:
        """Re-embed every document with the current Hugging Face embedding model."""
        data = self._collection.get(include=["documents", "metadatas"])
        ids = data.get("ids") or []
        docs = data.get("documents") or []
        metas = data.get("metadatas") or []
        if not ids:
            return 0

        settings = get_settings()
        name = settings.chroma_collection
        self._client.delete_collection(name)
        self._collection = self._client.get_or_create_collection(
            name=name,
            metadata={"hnsw:space": "cosine"},
        )

        count = 0
        for doc_id, doc, meta in zip(ids, docs, metas):
            if not doc:
                continue
            row_meta = dict(meta or {})
            row_meta["embedding"] = (
                "huggingface" if self._hf.is_configured else "fallback"
            )
            embedding = self._hf.embed(doc)
            self._collection.add(
                ids=[doc_id],
                documents=[doc],
                embeddings=[embedding],
                metadatas=[row_meta],
            )
            count += 1
        logger.info("Reindexed %d documents in collection %s", count, name)
        return count

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

        distances = [
            hit["distance"]
            for hit in hits
            if hit.get("distance") is not None
        ]
        if distances and min(distances) > self._max_distance:
            logger.info(
                "Best Chroma distance %.3f above threshold %.3f; no context",
                min(distances),
                self._max_distance,
            )
            return ""

        seen: set[str] = set()
        parts: list[str] = []
        for hit in hits:
            dist = hit.get("distance")
            if dist is not None and dist > self._max_distance:
                continue
            text = hit["text"].strip()
            if not text or text in seen:
                continue
            seen.add(text)
            parts.append(text)
        if not parts:
            return ""
        return "\n".join(f"{i}. {t}" for i, t in enumerate(parts, 1))

    def count(self) -> int:
        return self._collection.count()

    _SEED_DOCUMENTS: tuple[str, ...] = (
        "LangGraph (by LangChain) is a library for building stateful AI agent "
        "workflows as graphs. In this app it runs a retrieve-then-generate pipeline: "
        "search ChromaDB for context, then call Hugging Face to answer.",
        "This AI chat app uses LangGraph to orchestrate retrieve-then-generate workflows.",
        "ChromaDB stores document embeddings for semantic search and RAG.",
        "RAG (retrieval-augmented generation) means: retrieve relevant documents from "
        "ChromaDB, then generate an answer with Hugging Face using that context.",
        "Hugging Face Inference API provides chat and embedding models.",
        "The capital of India is New Delhi. It is the seat of the Government of India.",
        "Add your own knowledge via POST /api/knowledge to improve answers.",
    )

    def seed_defaults(self) -> int:
        """Insert built-in knowledge when the collection is empty."""
        if self.count() > 0:
            return 0
        for text in self._SEED_DOCUMENTS:
            self.add_document(text, {"source": "seed"})
        return len(self._SEED_DOCUMENTS)

    def ensure_core_knowledge(self) -> int:
        """Seed on first run; backfill any missing built-in documents."""
        if self.count() == 0:
            return self.seed_defaults()
        try:
            existing = self._collection.get(
                where={"source": "seed"},
                include=["documents"],
            )
            existing_texts = set(existing.get("documents") or [])
        except Exception as e:
            logger.warning("Could not read seed documents: %s", e)
            existing_texts = set()
        added = 0
        for text in self._SEED_DOCUMENTS:
            if text not in existing_texts:
                self.add_document(text, {"source": "seed"})
                added += 1
        return added
