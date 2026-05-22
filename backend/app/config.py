from functools import lru_cache
from pathlib import Path

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Always load backend/.env regardless of process working directory.
_BACKEND_DIR = Path(__file__).resolve().parent.parent
_ENV_FILE = _BACKEND_DIR / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    huggingface_api_key: str = ""
    hf_provider: str = "featherless-ai"
    hf_chat_model: str = "HuggingFaceH4/zephyr-7b-beta"
    hf_embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    hf_max_tokens: int = 256
    hf_temperature: float = 0.3
    chroma_persist_dir: str = str(_BACKEND_DIR / "chroma_data")
    chroma_collection: str = "knowledge"
    rag_top_k: int = 4
    rag_max_distance: float = 0.72
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    @property
    def has_hf_token(self) -> bool:
        return bool(self.huggingface_api_key.strip())

    @model_validator(mode="after")
    def _resolve_paths(self) -> "Settings":
        chroma = Path(self.chroma_persist_dir)
        if not chroma.is_absolute():
            self.chroma_persist_dir = str((_BACKEND_DIR / chroma).resolve())
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
