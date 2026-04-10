"""
main.py — KinoVibe API Server v3.2
FastAPI + Uvicorn + WebSocket signaling
"""

import logging
import uvicorn
from fastapi import FastAPI, HTTPException, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from search import execute_search          # ФИКС: было search_videos
from core.key_pool import get_pool         # ФИКС: было from key_pool
from signaling import get_signaling

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s >> %(name)s >> %(levelname)s >> %(message)s",
)
logger = logging.getLogger("kinovibe")

app = FastAPI(
    title="KinoVibe API",
    version="3.2.0",
    description="Кинематографический AI. Настроение → Фильм.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class SearchRequest(BaseModel):
    query: str
    category: str = "movies"


class CreateRoomRequest(BaseModel):
    movie_url: str = ""
    movie_title: str = ""


@app.get("/health")
async def health():
    return {"status": "ok", "version": "3.2.0", "service": "KinoVibe"}


@app.get("/pool/status")
async def pool_status():
    return get_pool().status()


@app.post("/search")
async def search(req: SearchRequest):
    if not req.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")
    logger.info(f"[SEARCH] query={req.query!r} category={req.category}")
    raw = await execute_search(req.query, req.category)   # ФИКС: правильное имя
    # Маппинг: клиент ждёт {"results": [...]}
    return {
        "results": raw.get("items", []),
        "query": raw.get("metadata", {}).get("query", req.query),
        "mood": raw.get("metadata", {}).get("mood"),
        "genre": raw.get("metadata", {}).get("genre"),
        "provider": "gemini",
        "category": req.category,
    }


@app.get("/stream")
async def get_stream_url(url: str):
    if not url:
        raise HTTPException(status_code=400, detail="url required")

    import asyncio, subprocess
    logger.info(f"[STREAM] Extracting: {url[:80]}")

    def _extract(u: str) -> dict:
        for fmt in ["bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"]:
            try:
                r = subprocess.run(
                    ["yt-dlp", "-g", "-f", fmt, "--no-playlist", u],
                    capture_output=True, text=True, timeout=20
                )
                if r.returncode == 0 and r.stdout.strip():
                    lines = r.stdout.strip().splitlines()
                    return {"stream_url": lines[0], "audio_url": lines[1] if len(lines) > 1 else None}
            except Exception:
                continue
        return {}

    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(None, _extract, url)

    if not result:
        raise HTTPException(status_code=422, detail="Could not extract stream URL")

    logger.info(f"[STREAM] OK: {result['stream_url'][:60]}...")
    return result


@app.post("/rooms/create")
async def create_room(req: CreateRoomRequest):
    room_id = get_signaling().create_room(
        movie_url=req.movie_url,
        movie_title=req.movie_title,
    )
    return {"room_id": room_id}


@app.get("/rooms")
async def list_rooms():
    return get_signaling().room_list()


@app.websocket("/ws/{peer_id}")
async def websocket_endpoint(ws: WebSocket, peer_id: str):
    await get_signaling().handle(ws, peer_id)


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False, log_level="info")
