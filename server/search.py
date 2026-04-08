# ============================================
# server/search.py
# DATE: 2026-04-09
# VERSION: 5.1.0
# PURPOSE: Full Search Pipeline (Gemini 2.5 SDK + KeyPool + yt-dlp)
# ============================================

import json
import asyncio
import subprocess
import time
import logging
import google.generativeai as genai
from core.key_pool import get_pool, AllExhaustedError

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("KINOVIBE_SEARCH")

MODEL_NAME = "gemini-2.5-flash"

SYSTEM_PROMPT = """You are a cinema expert AI. 
Task: Convert user mood/description into a surgical YouTube search query.
Rules:
1. Result must be ONLY valid JSON.
2. Query must be in English, 3-6 keywords.
3. Always append the specific category suffix.
Format: {"query": "string", "mood": "string", "genre": "string"}"""

CATEGORY_SUFFIX = {
    "movies": "full movie",
    "series": "full series episode 1",
    "shorts": "short film",
    "anime": "anime full episode"
}

async def ai_query_refiner(user_prompt: str, category: str) -> dict:
    """Трансформация запроса пользователя в поисковый запрос через Gemini SDK."""
    pool = get_pool()
    suffix = CATEGORY_SUFFIX.get(category, "full movie")
    
    try:
        entry, provider = pool.get_best(prefer="gemini")
    except AllExhaustedError as e:
        logger.error(f"Critical: {e}")
        return {"query": f"{user_prompt} {suffix}", "fallback": True}

    t0 = time.monotonic()
    genai.configure(api_key=entry.value)
    model = genai.GenerativeModel(
        model_name=MODEL_NAME,
        system_instruction=SYSTEM_PROMPT
    )

    try:
        # Вызов SDK
        full_prompt = f"User input: '{user_prompt}'. Category: '{category}'. Suffix: '{suffix}'."
        response = await model.generate_content_async(full_prompt)
        
        latency = time.monotonic() - t0
        raw_text = response.text.strip().replace("```json", "").replace("```", "")
        data = json.loads(raw_text)
        
        # Репорт об успехе
        tokens = len(raw_text) // 4
        pool.report(entry, code=200, tokens=tokens, latency=latency, model=MODEL_NAME)
        
        return data

    except Exception as e:
        latency = time.monotonic() - t0
        logger.warning(f"AI Refiner failed: {e}")
        
        # Определение кода ошибки для пула
        err_code = 429 if "429" in str(e) or "quota" in str(e).lower() else 500
        pool.report(entry, code=err_code, latency=latency, model=MODEL_NAME)
        
        return {"query": f"{user_prompt} {suffix}", "error": str(e)}

def _run_ytdlp(query: str, max_results: int = 10) -> list:
    """Синхронная обертка для yt-dlp (выполняется в отдельном потоке)."""
    cmd = [
        "yt-dlp",
        "--dump-json",
        "--no-playlist",
        "--skip-download",
        f"ytsearch{max_results}:{query}"
    ]
    try:
        process = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        results = []
        for line in process.stdout.splitlines():
            try:
                item = json.loads(line)
                results.append({
                    "id": item.get("id"),
                    "title": item.get("title"),
                    "url": item.get("webpage_url"),
                    "thumbnail": item.get("thumbnail"),
                    "duration": item.get("duration"),
                    "channel": item.get("uploader")
                })
            except: continue
        return results
    except Exception as e:
        logger.error(f"yt-dlp error: {e}")
        return []

async def execute_search(user_text: str, category: str = "movies"):
    """Основная точка входа: AI-обработка + Поиск."""
    logger.info(f"Starting search for: {user_text} in {category}")
    
    # 1. Получаем уточненный запрос от AI
    refined_data = await ai_query_refiner(user_text, category)
    target_query = refined_data.get("query")
    
    logger.info(f"Refined query: {target_query}")

    # 2. Запускаем поиск через yt-dlp в executor (не блокируя event loop)
    loop = asyncio.get_running_loop()
    results = await loop.run_in_executor(None, _run_ytdlp, target_query)
    
    return {
        "metadata": refined_data,
        "items": results,
        "count": len(results),
        "timestamp": time.time()
    }

# --- Тестовый запуск ---
if __name__ == "__main__":
    # Для теста в консоли: python search.py
    async def test():
        res = await execute_search("хочу что-то в стиле киберпанк, неоновое и мрачное", "movies")
        print(json.dumps(res, indent=2, ensure_ascii=False))
    
    asyncio.run(test())
