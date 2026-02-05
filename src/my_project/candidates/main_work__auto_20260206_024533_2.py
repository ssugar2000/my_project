# --- AUTO PATCH: ensure data dir exists ---
import os
os.makedirs("data", exist_ok=True)

import json, os

def main():
    os.makedirs('data', exist_ok=True)
    with open('data/output.json', 'w', encoding='utf-8') as f:
        json.dump({'status':'ok'}, f, ensure_ascii=False)

    print('main_work ?ㅽ뻾??)
    return 0

if __name__ == '__main__':
    raise SystemExit(main())