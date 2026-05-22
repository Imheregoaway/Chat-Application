from __future__ import annotations

import logging

from langchain_core.messages import AIMessage, HumanMessage
from langgraph.graph import END, StateGraph

from app.graph.query_utils import (
    allows_open_chat,
    context_is_relevant,
    is_inadequate_response,
    no_knowledge_message,
    should_use_rag,
    try_quick_reply,
)
from app.graph.state import AgentState
from app.services.chroma_service import ChromaService
from app.services.huggingface_service import HuggingFaceService

logger = logging.getLogger(__name__)


def _hf() -> HuggingFaceService:
    return HuggingFaceService()


def _chroma() -> ChromaService:
    return ChromaService(_hf())


def retrieve_node(state: AgentState) -> dict:
    """Retrieve relevant documents from ChromaDB (skipped for small talk)."""
    query = state["user_query"]
    if not should_use_rag(query):
        logger.info("Skipping RAG for small-talk query")
        return {"retrieved_context": ""}

    chroma = _chroma()
    hits = chroma.search(query, top_k=1)
    best_dist = hits[0].get("distance") if hits else None
    context = chroma.build_context(query)
    # Trust vector match when Chroma score is within threshold; only apply
    # keyword relevance for weak/borderline retrieval.
    if (
        context
        and not context_is_relevant(query, context)
        and (best_dist is None or best_dist > chroma.max_distance * 0.9)
    ):
        logger.info("Retrieved context not relevant to query; discarding")
        context = ""
    logger.info("Retrieved %d chars of context for query", len(context))
    return {"retrieved_context": context}


def generate_node(state: AgentState) -> dict:
    """Generate answer using Hugging Face with retrieved context."""
    query = state["user_query"]
    locale = state.get("locale", "en") or "en"
    context = (state.get("retrieved_context") or "").strip()

    history = []
    for msg in state.get("messages", [])[:-1]:
        if isinstance(msg, HumanMessage):
            history.append({"role": "user", "content": msg.content})
        elif isinstance(msg, AIMessage):
            history.append({"role": "assistant", "content": msg.content})

    use_rag = should_use_rag(query)
    open_chat = allows_open_chat(query)
    hf = _hf()

    if use_rag and not context and not open_chat:
        if hf.is_configured:
            logger.info("No Chroma context; falling back to general Hugging Face reply")
            response = hf.chat(
                user_message=query,
                context="",
                history=history,
                locale=locale,
                require_context=False,
            )
            if response.strip() and not is_inadequate_response(
                response, query, had_context=False
            ):
                return {
                    "final_response": response,
                    "no_knowledge": False,
                    "messages": [AIMessage(content=response)],
                }
        response = no_knowledge_message(locale)
        logger.info("No knowledge context for query; returning knowledge-gap message")
        return {
            "final_response": response,
            "no_knowledge": True,
            "messages": [AIMessage(content=response)],
        }

    response = hf.chat(
        user_message=query,
        context=context,
        history=history,
        locale=locale,
        require_context=use_rag and bool(context),
    )

    no_knowledge = False
    if use_rag and not open_chat:
        if not response.strip() or is_inadequate_response(
            response,
            query,
            had_context=bool(context),
        ):
            response = no_knowledge_message(locale)
            no_knowledge = True
            logger.info("Inadequate or empty model reply; returning knowledge-gap message")

    return {
        "final_response": response,
        "no_knowledge": no_knowledge,
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
        "no_knowledge": bool(result.get("no_knowledge", False)),
    }
