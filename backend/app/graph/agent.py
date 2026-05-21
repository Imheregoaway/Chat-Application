from __future__ import annotations

import logging

from langchain_core.messages import AIMessage, HumanMessage
from langgraph.graph import END, StateGraph

from app.graph.query_utils import should_use_rag, try_quick_reply
from app.graph.state import AgentState
from app.services.chroma_service import ChromaService
from app.services.huggingface_service import HuggingFaceService

logger = logging.getLogger(__name__)

_hf = HuggingFaceService()
_chroma = ChromaService(_hf)


def retrieve_node(state: AgentState) -> dict:
    """Retrieve relevant documents from ChromaDB (skipped for small talk)."""
    query = state["user_query"]
    if not should_use_rag(query):
        logger.info("Skipping RAG for small-talk query")
        return {"retrieved_context": ""}

    context = _chroma.build_context(query)
    logger.info("Retrieved %d chars of context for query", len(context))
    return {"retrieved_context": context}


def generate_node(state: AgentState) -> dict:
    """Generate answer using Hugging Face with retrieved context."""
    history = []
    for msg in state.get("messages", [])[:-1]:
        if isinstance(msg, HumanMessage):
            history.append({"role": "user", "content": msg.content})
        elif isinstance(msg, AIMessage):
            history.append({"role": "assistant", "content": msg.content})

    response = _hf.chat(
        user_message=state["user_query"],
        context=state.get("retrieved_context", ""),
        history=history,
        locale=state.get("locale", "en"),
    )
    return {
        "final_response": response,
        "messages": [AIMessage(content=response)],
    }


def build_agent():
    """LangGraph: retrieve from ChromaDB → generate with Hugging Face."""
    graph = StateGraph(AgentState)
    graph.add_node("retrieve", retrieve_node)
    graph.add_node("generate", generate_node)
    graph.set_entry_point("retrieve")
    graph.add_edge("retrieve", "generate")
    graph.add_edge("generate", END)
    return graph.compile()


_agent = None


def get_agent():
    global _agent
    if _agent is None:
        _agent = build_agent()
    return _agent


def run_agent(
    user_query: str,
    history: list[dict[str, str]] | None = None,
    locale: str = "en",
    attachments: list[str] | None = None,
) -> dict:
    """Execute the LangGraph pipeline."""
    query = user_query.strip()
    if attachments:
        extra = "\n\n".join(a for a in attachments if a.strip())
        if extra and extra not in query:
            query = f"{query}\n\n{extra}" if query else extra

    # Fast path: greetings / thanks / bye without LLM or RAG
    if not history and (quick := try_quick_reply(query)):
        return {"response": quick, "context": ""}

    messages = []
    for item in history or []:
        role = item.get("role", "user")
        content = item.get("content", "")
        if role == "assistant":
            messages.append(AIMessage(content=content))
        else:
            messages.append(HumanMessage(content=content))
    messages.append(HumanMessage(content=query))

    agent = get_agent()
    result = agent.invoke({
        "messages": messages,
        "user_query": query,
        "retrieved_context": "",
        "final_response": "",
        "locale": locale or "en",
    })
    return {
        "response": result.get("final_response", ""),
        "context": result.get("retrieved_context", ""),
    }
