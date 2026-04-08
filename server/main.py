# ============================================
# server/main.py
# DATE: 2026-04-09
# PURPOSE: FastAPI Hub (WebRTC Signaling + AI Search Gateway)
# VERSION: 3.5.0
# ============================================

import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict

# Импорт наших модулей
from core.key_pool import get_pool
from search import execute_search

app = FastAPI(title="KINOVIBE Backend", version="3.5.0")

# Настройка CORS для мобильных и web-клиентов
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Модели данных ────────────────────────────────────────────────────────────

class SearchRequest(BaseModel):
    query: str
    category: str = "movies"

# ─── Эндпоинты управления и диагностики ───────────────────────────────────────

@app.get("/health")
async def health_check():
    """Проверка доступности сервера."""
    return {"status": "online", "engine": "Gemini 2.5 Flash SDK"}

@app.get("/pool/status")
async def get_key_status():
    """Проверка состояния API-ключей Gemini и Groq."""
    pool = get_pool()
    return pool.status()

# ─── Эндпоинт AI-поиска ───────────────────────────────────────────────────────

@app.post("/search")
async def run_search(request: SearchRequest):
    """Выполнение поиска через Gemini 2.5 SDK и yt-dlp."""
    try:
        results = await execute_search(request.query, request.category)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ─── WebSocket: WebRTC Signaling & Watch Party Sync ──────────────────────────

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, room_id: str, websocket: WebSocket):
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append(websocket)

    def disconnect(self, room_id: str, websocket: WebSocket):
        if room_id in self.active_connections:
            self.active_connections[room_id].remove(websocket)

    async def broadcast(self, room_id: str, message: dict, sender: WebSocket):
        if room_id in self.active_connections:
            for connection in self.active_connections[room_id]:
                if connection != sender:
                    await connection.send_json(message)

manager = ConnectionManager()

@app.websocket("/ws/{room_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str):
    await manager.connect(room_id, websocket)
    try:
        while True:
            # Получаем сигнальные данные (SDP/ICE или Sync команды)
            data = await websocket.receive_json()
            await manager.broadcast(room_id, data, websocket)
    except WebSocketDisconnect:
        manager.disconnect(room_id, websocket)

# ─── Запуск ───────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Запуск на 0.0.0.0 для доступа из локальной сети Termux
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
