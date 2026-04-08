import os, mysql.connector, requests

def test():
    print(">> [CHECK]: MariaDB... ", end="")
    try:
        db = mysql.connector.connect(host="localhost", user="root", database="agent_core")
        print("OK")
    except Exception as e: print(f"FAIL: {e}")

    print(">> [CHECK]: Serper API... ", end="")
    s_key = os.getenv("SERPER_API_KEY")
    r = requests.post("https://google.serper.dev/search", 
                      headers={'X-API-KEY': s_key}, 
                      json={"q": "flutter webrtc fix"})
    print("OK" if r.status_code == 200 else f"FAIL: {r.status_code}")

    print(">> [CHECK]: Gemini Rotation... ", end="")
    g_keys = os.getenv("GEMINI_API_KEYS", "").split(",")
    print(f"LOADED {len(g_keys)} KEYS")

if __name__ == "__main__":
    test()
