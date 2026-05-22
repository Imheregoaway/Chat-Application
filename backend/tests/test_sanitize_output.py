from app.graph.query_utils import (
    allows_open_chat,
    context_is_relevant,
    echoes_query,
    is_inadequate_response,
    is_small_talk,
    no_knowledge_message,
    should_use_rag,
    try_quick_reply,
)
import numpy as np
import pytest

from app.services.huggingface_service import (
    _collapse_repeated_paragraphs,
    _flatten_embedding,
    _is_degenerate_repetition,
    _sanitize_chat_output,
)


def test_flatten_embedding_handles_numpy_ndarray():
    vec = np.array([0.1, -0.2, 0.3], dtype=np.float32)
    flat = _flatten_embedding(vec)
    assert len(flat) == 3
    assert flat[0] == pytest.approx(0.1)
    assert flat[1] == pytest.approx(-0.2)
    assert flat[2] == pytest.approx(0.3)


def test_sanitize_strips_inst_tokens():
    raw = "hello [/INST] hello [/INST] hello [/INST]"
    assert _sanitize_chat_output(raw) == "hello"


def test_sanitize_cuts_at_endoftext():
    raw = "Hi there!</s>more junk"
    assert _sanitize_chat_output(raw) == "Hi there!"


def test_sanitize_normal_reply_unchanged():
    raw = "LangGraph is a workflow library for building AI agents."
    assert _sanitize_chat_output(raw) == raw


def test_degenerate_repetition_detected():
    text = "hello " * 50
    assert _is_degenerate_repetition(text) is True


def test_greeting_detection():
    assert is_small_talk("hello")
    assert is_small_talk("Hi!")
    assert try_quick_reply("hello") is not None
    assert not is_small_talk("What is LangGraph?")


def test_no_knowledge_message_english():
    assert "knowledge base" in no_knowledge_message("en").lower()


def test_allows_open_chat_for_brainstorm():
    assert allows_open_chat("Help me brainstorm app ideas")
    assert not allows_open_chat("how to make pasta")


def test_inadequate_response_detects_fragments():
    assert is_inadequate_response("from scratch", had_context=False)
    assert not is_inadequate_response("New Delhi is the capital of India.", had_context=False)


def test_echoes_query_detects_rephrase():
    assert echoes_query("how to cook pasta", "how to make pasta")
    assert not echoes_query(
        "New Delhi is the capital of India.",
        "India capital",
    )


def test_context_is_relevant_for_pasta_query():
    kb = "LangGraph orchestrates retrieve-then-generate workflows."
    assert not context_is_relevant("how to make pasta", kb)
    kb_india = "The capital of India is New Delhi."
    assert context_is_relevant("India capital", kb_india)


def test_inadequate_how_to_without_steps():
    assert is_inadequate_response(
        "how to cook pasta",
        "how to make pasta",
        had_context=True,
    )


def test_should_use_rag_for_short_factual_queries():
    assert should_use_rag("india capital")
    assert should_use_rag("What is LangGraph?")
    assert not should_use_rag("hello")
    assert not should_use_rag("thanks")


def test_sanitize_strips_usr_ass_tokens():
    raw = "New Delhi [/USR] extra [/ASS] more junk"
    out = _sanitize_chat_output(raw)
    assert "[/USR]" not in out
    assert "[/ASS]" not in out
    assert "New Delhi" in out


def test_collapse_repeated_paragraphs():
    para = "LangGraph is a workflow library for AI agents."
    raw = f"{para}\n\n{para}\n\n{para}"
    assert _collapse_repeated_paragraphs(raw) == para


def test_strips_user_template_leak():
    raw = (
        "[/USER] Can you provide me with a step-by-step guide on spaghetti?\n\n"
        "Generate according to: Spaghetti is a type of long pasta.\n\n"
        "1. Boil water.\n2. Cook pasta.\n\n"
        "[/USER] Remove this"
    )
    out = _sanitize_chat_output(
        raw,
        user_message="Can you provide me with a step-by-step guide on spaghetti?",
    )
    assert "[/USER]" not in out
    assert "Generate according to" not in out
    assert "Remove this" not in out
    assert "1." in out
