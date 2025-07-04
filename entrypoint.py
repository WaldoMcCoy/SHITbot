Creating entrypoint.py...
import os, sys, json, subprocess
from pathlib import Path
print("[INFO] Starting S.H.I.T. Bot via Python entrypoint...")
if not os.getenv('BOT_TOKEN'): 
    print("[ERROR] BOT_TOKEN not set!"); sys.exit(1)
for d in ['/app/data/db','/app/data/tokens','/app/data/routers','/app/logs']:
    Path(d).mkdir(parents=True, exist_ok=True)
for f in ['token_cache','router_cache','bridge_cache','price_cache']:
    p = Path(f'/app/data/{f.split("_")[0]}s/{f}.json')
    if not p.exists(): p.write_text('{}'^
print("[INFO] Initialization complete, starting main.py...")
os.execvp(sys.executable, [sys.executable, 'main.py'])
