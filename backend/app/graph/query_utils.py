"""Helpers to classify user queries and handle simple replies without the LLM."""

from __future__ import annotations

import re
from difflib import SequenceMatcher

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
    """Skip vector search only for greetings, thanks, and goodbye."""
    return not is_small_talk(query)


_OPEN_CHAT = re.compile(
    r"brainstorm|app\s+ideas?|creative|write\s+(a\s+)?(story|poem|song|email)|"
    r"tell\s+me\s+a\s+joke|joke|imagine|roleplay|chat\s+with\s+me",
    re.IGNORECASE,
)


def allows_open_chat(query: str) -> bool:
    """Allow general LLM replies without knowledge-base context."""
    return bool(_OPEN_CHAT.search(query.strip()))


_NO_KNOWLEDGE_MESSAGES: dict[str, str] = {
    "en": (
        "I don't have information about that in my knowledge base. "
        "Add relevant content under Settings → Add Knowledge, then ask again."
    ),
    "es": (
        "No tengo información sobre eso en mi base de conocimientos. "
        "Añade contenido en Ajustes → Añadir conocimiento e inténtalo de nuevo."
    ),
    "fr": (
        "Je n'ai pas d'information à ce sujet dans ma base de connaissances. "
        "Ajoutez du contenu dans Paramètres → Ajouter des connaissances, puis réessayez."
    ),
    "de": (
        "Dazu habe ich keine Informationen in meiner Wissensdatenbank. "
        "Fügen Sie Inhalte unter Einstellungen → Wissen hinzufügen hinzu und fragen Sie erneut."
    ),
    "hi": (
        "मेरे ज्ञान भंडार में इस विषय की जानकारी नहीं है। "
        "सेटिंग्स → ज्ञान जोड़ें में सामग्री जोड़कर पुनः पूछें।"
    ),
}


def no_knowledge_message(locale: str = "en") -> str:
    code = (locale or "en").split("-")[0].lower()
    return _NO_KNOWLEDGE_MESSAGES.get(code, _NO_KNOWLEDGE_MESSAGES["en"])


_STOPWORDS = frozenset({
    "how", "what", "when", "where", "who", "why", "which",
    "is", "are", "was", "were", "the", "a", "an", "to", "of", "in", "for",
    "on", "at", "by", "with", "about", "from", "into", "your", "my", "me",
    "do", "does", "did", "can", "could", "would", "should", "will", "you",
    "i", "we", "they", "it", "this", "that", "and", "or", "not", "any",
})

_HOW_TO_QUERY = re.compile(
    r"\b(how\s+to|how\s+do\s+i|how\s+can\s+i|steps?\s+to|recipe\s+for)\b",
    re.IGNORECASE,
)


def _normalize_words(text: str) -> str:
    return " ".join(re.findall(r"[a-z0-9']+", text.lower()))


def _significant_terms(text: str) -> set[str]:
    return {
        w
        for w in re.findall(r"[a-z0-9']+", text.lower())
        if len(w) >= 3 and w not in _STOPWORDS
    }


def _term_in_text(term: str, haystack: str) -> bool:
    if term in haystack:
        return True
    for word in re.findall(r"[a-z]+", haystack.lower()):
        if len(term) >= 4 and len(word) >= 4:
            if SequenceMatcher(None, term, word).ratio() >= 0.82:
                return True
    return False


def context_is_relevant(query: str, context: str) -> bool:
    """True when retrieved knowledge plausibly relates to the user's question."""
    if not context.strip():
        return False

    terms = _significant_terms(query)
    if not terms:
        return True

    haystack = context.lower()
    matched = sum(1 for term in terms if _term_in_text(term, haystack))
    required = 1 if len(terms) <= 3 else max(1, len(terms) // 2)
    return matched >= required


def echoes_query(response: str, query: str) -> bool:
    """True when the model mostly repeats or rephrases the question."""
    resp = _normalize_words(response)
    q = _normalize_words(query)
    if not resp or not q:
        return False
    if resp == q:
        return True
    if SequenceMatcher(None, resp, q).ratio() >= 0.72:
        return True

    resp_terms = set(resp.split())
    query_terms = set(q.split())
    if not query_terms:
        return False
    overlap = len(resp_terms & query_terms) / len(query_terms)
    return overlap >= 0.75 and len(resp_terms) <= len(query_terms) + 2


def is_how_to_query(query: str) -> bool:
    return bool(_HOW_TO_QUERY.search(query))


def lacks_how_to_substance(response: str) -> bool:
    """How-to answers should be more than a short phrase; prefer steps or detail."""
    text = response.strip()
    if len(text) < 60:
        return True
    if re.search(
        r"\b(\d+[\.\)]|first|second|then|next|step|boil|add|mix|stir|cook|bake|serve)\b",
        text,
        re.IGNORECASE,
    ):
        return False
    return len(text.split()) < 12


def is_inadequate_response(
    response: str,
    query: str = "",
    *,
    had_context: bool = False,
) -> bool:
    """Detect empty, fragment, echo, or useless model outputs."""
    text = response.strip()
    if not text:
        return True

    words = text.split()
    lowered = text.lower()

    if query and echoes_query(text, query):
        return True

    if query and is_how_to_query(query) and lacks_how_to_substance(text):
        return True

    if lowered in {
        "from scratch",
        "yes",
        "no",
        "ok",
        "sure",
        "maybe",
        "n/a",
        "unknown",
    }:
        return True

    if had_context:
        return len(words) <= 2 or (len(text) < 40 and len(words) <= 6)

    return len(words) <= 3 and len(text) < 50
