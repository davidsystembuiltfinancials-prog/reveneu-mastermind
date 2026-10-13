#!/usr/bin/env python3
"""
Generate animated agent sprite sheets for the ARES Station GUI via the PixelLab API.

Each agent gets a 4-column x 8-row sheet at 40px frames (160x320), matching the
layout main.tsx expects:

    row 0 idle-front   row 4 walk-front
    row 1 idle-back    row 5 walk-back
    row 2 idle-left    row 6 walk-left
    row 3 idle-right   row 7 walk-right

Pipeline per agent:
  1. generate-image-pixflux  -> one 64px reference (south / front, idle)
  2. animate-with-text (x8)   -> 4 frames per (direction, action); 64px each
  3. downscale 64 -> 40 and compose the sheet (transparent background)

Raw 64px frames are cached under a work dir so re-runs resume and skip
already-generated calls. The API key is read from env PIXELLAB_API_KEY and is
never written to disk.

Usage:
  PIXELLAB_API_KEY=... python3 generate-agent-sprites.py [--only ID[,ID...]]
                                                          [--work DIR]
                                                          [--out DIR]
                                                          [--preview]
"""
import argparse
import base64
import io
import json
import os
import sys
import time
import urllib.error
import urllib.request

from PIL import Image

API_BASE = "https://api.pixellab.ai/v1"
FRAME_SRC = 64          # animate-with-text is locked to 64x64
FRAME_DST = 40          # sheet cell size main.tsx samples
COLS = 4                # frames per animation row
VIEW = "low top-down"

# front=toward viewer, back=away, left/right profile
DIRECTION = {"front": "south", "back": "north", "left": "west", "right": "east"}
# sheet row order expected by main.tsx animationRows
ROW_ORDER = [
    ("idle", "front"), ("idle", "back"), ("idle", "left"), ("idle", "right"),
    ("walk", "front"), ("walk", "back"), ("walk", "left"), ("walk", "right"),
]
ACTION_PROMPT = {
    "idle": "standing still at attention, subtle idle breathing, minimal motion",
    "walk": "walking, clear walk cycle, legs striding",
}

STYLE = (
    "pixel art game sprite, slim humanoid astronaut robot crew member, "
    "smooth white and light-grey armored spacesuit, rounded helmet with a "
    "glowing {accent} glass visor, small glowing chest light, clean sci-fi, "
    "simple cel shading, full body, centered, transparent background"
)

# 13 agents, matched to main.tsx ids / accent colors / roles
AGENTS = [
    ("overseer",    "pale mint-white", "station commander with a small shoulder antenna"),
    ("research-a",  "cyan",            "researcher holding a small handheld scanner"),
    ("research-b",  "cyan",            "researcher holding a small specimen vial"),
    ("media-a",     "magenta",         "media operator wearing headphones"),
    ("audit",       "gold yellow",     "auditor holding a small ledger tablet"),
    ("engineer-a",  "amber orange",    "engineer with a tool belt and a wrench"),
    ("engineer-b",  "orange",          "engineer with a tool belt and a power drill"),
    ("comm",        "spring green",    "comms officer with a headset and antenna"),
    ("signal",      "teal",            "signal watcher with a radar-dish visor"),
    ("archivist",   "violet purple",   "archivist carrying a glowing data tome"),
    ("warden",      "red",             "tool warden with heavy shoulder armor pads"),
    ("attendant",   "light green",     "medical attendant with a glowing cross emblem"),
]
# note: main.tsx maps both engineers + media; sheet filenames use these ids.
SHEET_NAME = {
    "overseer": "overseer-sheet.png",
    "research-a": "research-a-sheet.png",
    "research-b": "research-b-sheet.png",
    "media-a": "media-a-sheet.png",
    "audit": "audit-sheet.png",
    "engineer-a": "engineer-a-sheet.png",
    "engineer-b": "engineer-b-sheet.png",
    "comm": "comm-sheet.png",
    "signal": "signal-sheet.png",
    "archivist": "archivist-sheet.png",
    "warden": "warden-sheet.png",
    "attendant": "attendant-sheet.png",
}


def api_key():
    k = os.environ.get("PIXELLAB_API_KEY")
    if not k:
        sys.exit("PIXELLAB_API_KEY not set in environment")
    return k


def post(path, payload, retries=4):
    data = json.dumps(payload).encode()
    url = f"{API_BASE}{path}"
    last = None
    for attempt in range(retries):
        req = urllib.request.Request(
            url, data=data, method="POST",
            headers={
                "Authorization": f"Bearer {api_key()}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")
            last = f"HTTP {e.code}: {body[:300]}"
            if e.code in (429, 500, 502, 503, 504):
                wait = 2 ** (attempt + 1)
                print(f"    retry in {wait}s ({last})")
                time.sleep(wait)
                continue
            raise SystemExit(f"API error {path}: {last}")
        except (urllib.error.URLError, TimeoutError) as e:
            last = str(e)
            wait = 2 ** (attempt + 1)
            print(f"    net retry in {wait}s ({last})")
            time.sleep(wait)
    raise SystemExit(f"API failed after {retries} tries {path}: {last}")


def b64_to_img(b64):
    return Image.open(io.BytesIO(base64.b64decode(b64))).convert("RGBA")


def gen_reference(desc, work, agent_id):
    path = os.path.join(work, f"{agent_id}__ref.png")
    if os.path.exists(path):
        return Image.open(path).convert("RGBA")
    print(f"  pixflux reference ...")
    resp = post("/generate-image-pixflux", {
        "description": desc,
        "image_size": {"width": FRAME_SRC, "height": FRAME_SRC},
        "view": VIEW,
        "direction": "south",
        "no_background": True,
    })
    img = b64_to_img(resp["image"]["base64"])
    img.save(path)
    return img


def gen_anim(desc, action, facing, ref_img, work, agent_id):
    """Return list of 4 RGBA 64px frames for (action, facing), cached."""
    frames = []
    cache = [os.path.join(work, f"{agent_id}__{action}__{facing}__{i}.png") for i in range(COLS)]
    if all(os.path.exists(p) for p in cache):
        return [Image.open(p).convert("RGBA") for p in cache]

    buf = io.BytesIO()
    ref_img.save(buf, format="PNG")
    ref_b64 = base64.b64encode(buf.getvalue()).decode()

    print(f"  animate {action}-{facing} ({DIRECTION[facing]}) ...")
    resp = post("/animate-with-text", {
        "description": desc,
        "action": ACTION_PROMPT[action],
        "image_size": {"width": FRAME_SRC, "height": FRAME_SRC},
        "view": VIEW,
        "direction": DIRECTION[facing],
        "n_frames": COLS,
        "reference_image": {"type": "base64", "base64": ref_b64},
    })
    imgs = [b64_to_img(im["base64"]) for im in resp["images"]]
    while len(imgs) < COLS:          # safety: pad if fewer returned
        imgs.append(imgs[-1].copy())
    for p, im in zip(cache, imgs[:COLS]):
        im.save(p)
    return imgs[:COLS]


def downscale(img):
    if img.size != (FRAME_SRC, FRAME_SRC):
        img = img.resize((FRAME_SRC, FRAME_SRC), Image.NEAREST)
    return img.resize((FRAME_DST, FRAME_DST), Image.LANCZOS)


def build_agent(agent_id, accent, role, work, out):
    desc = f"{role}, {STYLE.format(accent=accent)}"
    os.makedirs(work, exist_ok=True)
    print(f"[{agent_id}] {role}")
    ref = gen_reference(desc, work, agent_id)

    sheet = Image.new("RGBA", (FRAME_DST * COLS, FRAME_DST * len(ROW_ORDER)), (0, 0, 0, 0))
    for row, (action, facing) in enumerate(ROW_ORDER):
        frames = gen_anim(desc, action, facing, ref, work, agent_id)
        for col, frame in enumerate(frames):
            sheet.paste(downscale(frame), (col * FRAME_DST, row * FRAME_DST))

    os.makedirs(out, exist_ok=True)
    dest = os.path.join(out, SHEET_NAME[agent_id])
    sheet.save(dest)
    print(f"  -> {dest}")
    return dest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="comma-separated agent ids")
    ap.add_argument("--work", default=os.path.expanduser("~/sprite-work"))
    ap.add_argument("--out", required=True, help="sheets output dir")
    ap.add_argument("--preview", action="store_true",
                    help="only generate front walk+idle for a quick look")
    args = ap.parse_args()

    agents = AGENTS
    if args.only:
        want = set(args.only.split(","))
        agents = [a for a in AGENTS if a[0] in want]
        if not agents:
            sys.exit(f"no agents match {args.only}")

    if args.preview:
        global ROW_ORDER
        ROW_ORDER = [("idle", "front"), ("walk", "front"),
                     ("walk", "left"), ("walk", "back")]

    for agent_id, accent, role in agents:
        build_agent(agent_id, accent, role, args.work, args.out)
    print("done")


if __name__ == "__main__":
    main()
