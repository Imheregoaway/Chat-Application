from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    huggingface_api_key: str = ""
    hf_provider: str = "featherless-ai"
    hf_chat_model: str = "HuggingFaceH4/zephyr-7b-beta"
    hf_embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    hf_max_tokens: int = 256
    hf_temperature: float = 0.6
    chroma_persist_dir: str = "./chroma_data"
    chroma_collection: str = "knowledge"
    rag_top_k: int = 4
    rag_max_distance: float = 0.75
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    @property
    def has_hf_token(self) -> bool:
        return bool(self.huggingface_api_key.strip())


@lru_cache
def get_settings() -> Settings:
    return Settings()
