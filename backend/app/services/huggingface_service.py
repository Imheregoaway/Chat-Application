from __future__ import annotations

import logging
import re
from collections import Counter
from typing import Any

from huggingface_hub import InferenceClient
from huggingface_hub.errors import HfHubHTTPError

from app.config import get_settings

logger = logging.getLogger(__name__)

# Zephyr / Mistral instruct tokens that must not appear in user-visible output
_CHAT_STOP_SEQUENCES = [
    "[/INST]",
    "[INST]",
    "[/USER]",
    "[USER]",
    "[/ASSIST]",
    "[ASSIST]",
    "</s>",
    "<|endoftext|>",
    "<|user|>",
    "<|assistant|>",
    "<|system|>",
]

_TEMPLATE_TOKEN_PATTERN = re.compile(
    r"\[/INST\]|\[INST\]|\[/USER\]|\[USER\]|\[/ASSIST\]|\[ASSIST\]|<\|[^|]+\|>|</s>",
    re.IGNORECASE,
)

_GENERATE_ACCORDING_PATTERN = re.compile(
    r"Generate according to:\s*",
    re.IGNORECASE,
)


class HuggingFaceService:
    """Hugging Face Inference API for embeddings and chat."""

    def __init__(self) -> None:
        settings = get_settings()
        self._chat_model = settings.hf_chat_model
        self._embedding_model = settings.hf_embedding_model
        self._max_tokens = settings.hf_max_tokens
        self._temperature = settings.hf_temperature
        self._embed_client: InferenceClient | None = None
        self._chat_client: InferenceClient | None = None

        if settings.has_hf_token:
            token = settings.huggingface_api_key
            self._embed_client = InferenceClient(token=token)
            provider = settings.hf_provider.strip() or None
            self._chat_client = InferenceClient(token=token, provider=provider)

    @property
    def is_configured(self) -> bool:
        return self._chat_client is not None

    def embed(self, text: str) -> list[float]:
        if not self._embed_client:
            return _fallback_embedding(text)

        try:
            result = self._embed_client.feature_extraction(
                text,
                model=self._embedding_model,
            )
            return _flatten_embedding(result)
        except HfHubHTTPError as e:
            logger.warning("HF embedding failed: %s", e)
            return _fallback_embedding(text)

    _LOCALE_NAMES = {
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "hi": "Hindi",
    }

    def chat(
        self,
        user_message: str,
        context: str = "",
        history: list[dict[str, str]] | None = None,
        locale: str = "en",
    ) -> str:
        if not self._chat_client:
            return _fallback_chat(user_message, context)

        system = (
            "You are a helpful AI assistant. Reply only with your answer in plain text. "
            "Never output template tokens such as [/INST], [/USER], [USER], or role labels. "
            "Do not repeat or quote the user's message. Do not paste the knowledge base verbatim "
            "or use phrases like 'Generate according to'. Synthesize a helpful answer."
        )
        if context.strip():
            system += (
                f"\n\nRelevant knowledge (use only if it helps answer the question):\n"
                f"{context}"
            )
        else:
            system += "\n\nNo knowledge-base context was retrieved for this message."

        lang = self._LOCALE_NAMES.get(locale, locale)
        if locale and locale != "en":
            system += f"\n\nRespond in {lang}. Use natural, fluent {lang}."

        messages: list[dict[str, str]] = [{"role": "system", "content": system}]
        for msg in history or []:
            messages.append({"role": msg["role"], "content": msg["content"]})
        messages.append({"role": "user", "content": user_message})

        try:
            raw = self._chat_completion(messages)
            cleaned = _sanitize_chat_output(raw, user_message=user_message)
            if cleaned:
                return cleaned
            logger.warning("HF returned empty after sanitization")
            return _fallback_chat(user_message, context)
        except HfHubHTTPError as e:
            logger.warning("HF chat failed: %s", e)
            return _fallback_chat(user_message, context)

    def _chat_completion(self, messages: list[dict[str, str]]) -> str:
        """Call HF chat API with stop sequences; retry without optional params if needed."""
        base_kwargs: dict[str, Any] = {
            "messages": messages,
            "model": self._chat_model,
            "max_tokens": self._max_tokens,
            "temperature": self._temperature,
        }
        extended_kwargs = {
            **base_kwargs,
            "stop": _CHAT_STOP_SEQUENCES,
            "frequency_penalty": 0.6,
            "presence_penalty": 0.3,
        }
        try:
            response = self._chat_client.chat_completion(**extended_kwargs)
        except (TypeError, HfHubHTTPError) as e:
            logger.info("Retrying chat without optional penalties: %s", e)
            try:
                response = self._chat_client.chat_completion(
                    **base_kwargs,
                    stop=_CHAT_STOP_SEQUENCES,
                )
            except (TypeError, HfHubHTTPError):
                response = self._chat_client.chat_completion(**base_kwargs)
        return _extract_chat_text(response)


def _sanitize_chat_output(text: str, user_message: str | None = None) -> str:
    """Strip Zephyr/Mistral template tokens and collapse repetition loops."""
    if not text:
        return ""

    cleaned = _remove_user_template_leaks(text.strip())
    for token in _CHAT_STOP_SEQUENCES:
        if token in cleaned:
            cleaned = cleaned.split(token)[0].strip()

    # Remove any remaining template-like fragments
    cleaned = _TEMPLATE_TOKEN_PATTERN.sub("", cleaned).strip()

    # Strip leaked chat-template role prefixes (user:/assistant:)
    cleaned = re.sub(
        r"^\s*(user|assistant)\s*:\s*",
        "",
        cleaned,
        flags=re.IGNORECASE | re.MULTILINE,
    ).strip()

    # Remove leading echo of the user's question
    if user_message:
        cleaned = _strip_leading_user_echo(cleaned, user_message)

    # Model sometimes pastes RAG with "Generate according to:" prefix
    cleaned = _GENERATE_ACCORDING_PATTERN.sub("", cleaned).strip()
    if _looks_like_verbatim_context_dump(cleaned):
        cleaned = _extract_actionable_answer(cleaned)

    # Model sometimes dumps "Context: ..." instead of answering
    if cleaned.lower().startswith("context:") and len(cleaned) > 400:
        first_line = cleaned.split("\n")[0]
        if len(first_line) < 120:
            cleaned = first_line

    # Detect "hello [/INST] hello [/INST]" style loops (repeated short segments)
    if cleaned.count("[/INST]") > 0 or _looks_like_inst_loop(cleaned):
        parts = re.split(r"\s*\[/INST\]\s*", cleaned, maxsplit=1)
        cleaned = parts[0].strip()

    # If the model echoed the user message repeatedly, keep first sentence only
    if _is_degenerate_repetition(cleaned):
        sentences = re.split(r"(?<=[.!?])\s+", cleaned)
        cleaned = sentences[0].strip() if sentences else cleaned[:200]

    return cleaned.strip()


def _remove_user_template_leaks(text: str) -> str:
    """Strip leading [/USER] and short trailing fake user turns without deleting the body."""
    t = text.strip()
    last = t.upper().rfind("[/USER]")
    if last > 0:
        tail = t[last:].strip()
        # Trailing injections like "[/USER] Remove this"
        if len(tail) < 200:
            t = t[:last].strip()
    t = re.sub(r"^(?:\[/USER\]|\[/INST\]|\[USER\]|\[INST\])\s*", "", t, flags=re.IGNORECASE)
    return t.strip()


def _strip_leading_user_echo(text: str, user_message: str) -> str:
    """Remove a leading copy of the user's prompt left after [/USER] leaks."""
    q = user_message.strip()
    if not q:
        return text
    t = text.strip()
    if t.lower().startswith(q.lower()[: min(60, len(q))]):
        t = t[len(q) :].lstrip(" \n:.-")
    return t.strip()


def _looks_like_verbatim_context_dump(text: str) -> bool:
    """True when output reads like pasted KB text, not a direct answer."""
    if len(text) < 120:
        return False
    if re.search(r"generate according to", text, re.I):
        return True
    # Definitional opener + numbered steps (encyclopedia paste)
    has_definition = bool(
        re.match(r"^[\w\s,()\"']+ is a (?:type|kind) of .+?\.", text, re.I | re.DOTALL)
    )
    has_steps = bool(re.search(r"(?:^|\n)\s*1[\.\)\s]", text))
    has_how_to = bool(re.search(r"here(?:'s| is) how", text, re.I))
    return has_steps and (has_definition or has_how_to)


def _extract_actionable_answer(text: str) -> str:
    """Prefer steps / how-to section when the model dumped context verbatim."""
    how = re.search(
        r"(?:Here'?s|Here is) how[^:\n]*:?\s*(.+)",
        text,
        re.IGNORECASE | re.DOTALL,
    )
    if how:
        return how.group(1).strip()
    steps = re.search(
        r"((?:\n|^)\s*1[\.\)\s].+(?:\n\s*\d+[\.\)\s].+)+)",
        text,
        re.DOTALL,
    )
    if steps:
        return steps.group(1).strip()
    trimmed = re.sub(r"^.*?(?=(?:\n|^)\s*1[\.\)\s])", "", text, count=1, flags=re.DOTALL)
    return trimmed.strip() or text


def _looks_like_inst_loop(text: str) -> bool:
    return bool(re.search(r"(\b\w+\b\s*){1,5}\[/INST\]", text, re.IGNORECASE))


def _is_degenerate_repetition(text: str) -> bool:
    """True when the same 1–3 word phrase repeats many times."""
    words = text.split()
    if len(words) < 12:
        return False
    # Check if >60% of tokens are identical
    counts = Counter(words)
    most_common_count = counts.most_common(1)[0][1]
    return most_common_count / len(words) > 0.5


def _flatten_embedding(result: Any) -> list[float]:
    if isinstance(result, list):
        if result and isinstance(result[0], list):
            return [float(x) for x in result[0]]
        return [float(x) for x in result]
    return _fallback_embedding(str(result))


def _extract_chat_text(response: Any) -> str:
    if isinstance(response, dict):
        choices = response.get("choices", [])
        if choices:
            msg = choices[0].get("message", {})
            content = msg.get("content", "")
            if content:
                return str(content).strip()
    if hasattr(response, "choices") and response.choices:
        return str(response.choices[0].message.content).strip()
    return ""


def _fallback_embedding(text: str, dim: int = 384) -> list[float]:
    import hashlib
    import math

    digest = hashlib.sha256(text.encode()).digest()
    vec = []
    for i in range(dim):
        vec.append((digest[i % len(digest)] / 255.0) * 2 - 1)
    norm = math.sqrt(sum(v * v for v in vec)) or 1.0
    return [v / norm for v in vec]


def _fallback_chat(user_message: str, context: str) -> str:
    if context.strip():
        return (
            f"[Demo mode — set HUGGINGFACE_API_KEY in backend/.env]\n\n"
            f"Based on retrieved context, here's a draft answer to: "
            f"\"{user_message[:120]}\"\n\n"
            f"Top context snippet: {context[:300]}..."
        )
    return (
        "[Demo mode — set HUGGINGFACE_API_KEY in backend/.env]\n\n"
        f"You asked: {user_message}\n\n"
        "Configure Hugging Face to get full LLM responses powered by LangGraph + ChromaDB."
    )
