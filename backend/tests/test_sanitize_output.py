from app.graph.query_utils import is_small_talk, try_quick_reply
from app.services.huggingface_service import _is_degenerate_repetition, _sanitize_chat_output


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
