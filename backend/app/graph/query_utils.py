"""Helpers to classify user queries and handle simple replies without the LLM."""

from __future__ import annotations

import re

_GREETING = re.compile(
    r"^(hi|hello|hey|howdy|yo|greetings|good\s+(morning|afternoon|evening)|"
    r"what'?s\s+up|sup)[\s!.,?]*$",
    re.IGNORECASE,
)

_THANKS = re.compile(
    r"^(thanks|thank\s+you|thx|ty)[\s!.,?]*$",
    re.IGNORECASE,
)

_BYE = re.compile(
    r"^(bye|goodbye|see\s+you|later|cya)[\s!.,?]*$",
    re.IGNORECASE,
)


def is_small_talk(query: str) -> bool:
    """True for greetings, thanks, goodbye — skip RAG for these."""
    text = query.strip()
    if not text or len(text) > 80:
        return False
    return bool(_GREETING.match(text) or _THANKS.match(text) or _BYE.match(text))


def try_quick_reply(query: str) -> str | None:
    """Instant reply without calling Hugging Face (saves tokens + avoids template bugs)."""
    text = query.strip()
    if _GREETING.match(text):
        return (
            "Hello! I'm your AI assistant. I use LangGraph for reasoning, "
            "ChromaDB for knowledge search, and Hugging Face for answers. "
            "What would you like to know?"
        )
    if _THANKS.match(text):
        return "You're welcome! Let me know if you need anything else."
    if _BYE.match(text):
        return "Goodbye! Come back anytime you want to chat."
    return None


def should_use_rag(query: str) -> bool:
    """Skip vector search for small talk and very short non-questions."""
    if is_small_talk(query):
        return False
    words = query.strip().split()
    if len(words) <= 2 and "?" not in query:
        return False
    return True
