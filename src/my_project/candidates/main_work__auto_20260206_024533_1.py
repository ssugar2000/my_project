# --- AUTO PATCH: ensure artifact json exists ---
import os, json

def _ensure_artifact():
    os.makedirs(os.path.dirname(r"data/output.json") or ".", exist_ok=True)
    with open(r"data/output.json", "w", encoding="utf-8") as f:
        f.write('{"status":"ok"}')

import json, os

def main():
    _ensure_artifact()
    os.makedirs('data', exist_ok=True)
    with open('data/output.json', 'w', encoding='utf-8') as f:
        json.dump({'status':'ok'}, f, ensure_ascii=False)

    print('main_work ?ㅽ뻾??)
    return 0

if __name__ == '__main__':
    raise SystemExit(main())