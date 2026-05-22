import os
from pathlib import Path

import uvicorn

from app.config import _BACKEND_DIR, get_settings

if __name__ == "__main__":
    os.chdir(_BACKEND_DIR)
    get_settings.cache_clear()
    settings = get_settings()
    uvicorn.run(
        "app.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=True,
    )
