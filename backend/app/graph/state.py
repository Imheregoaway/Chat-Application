from __future__ import annotations

from typing import Annotated, TypedDict

from langgraph.graph.message import add_messages


class AgentState(TypedDict):
    """State passed through the LangGraph agent."""

    messages: Annotated[list, add_messages]
    user_query: str
    retrieved_context: str
    final_response: str
    locale: str
