from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    role: str = Field(..., pattern="^(user|assistant)$")
    content: str


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=8000)
    history: list[ChatMessage] = Field(default_factory=list)
    locale: str = Field(default="en", max_length=8)
    attachments: list[str] = Field(default_factory=list)


class ChatResponse(BaseModel):
    response: str
    context_used: str = ""
    sources_count: int = 0


class KnowledgeRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=16000)
    source: str = "user"


class KnowledgeResponse(BaseModel):
    id: str
    message: str


class HealthResponse(BaseModel):
    status: str
    huggingface_configured: bool
    chroma_documents: int
    chat_model: str
    embedding_model: str
    inference_provider: str = ""
