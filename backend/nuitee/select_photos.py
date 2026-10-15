"""Select at most five distinct provider photos before storing a gallery.

Usage: python select_photos.py candidates.json output.json --cache-dir /tmp/photos
Requires Pillow. Run inside the trusted import worker, never accept caller hashes.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
from urllib.parse import urlsplit
from urllib.request import urlopen

from PIL import Image, ImageOps

MAX_PHOTOS = 5
MAX_BYTES = 20 * 1024 * 1024
ALGORITHM = "sha256+dhash64-v1"


def fingerprint(data):
    with Image.open(io.BytesIO(data)) as raw:
        raw.load()
        image = ImageOps.exif_transpose(raw).convert("L")
        if min(image.size) < 100:
            raise ValueError("Photo too small")
        pixels = list(image.resize((9, 8), Image.Resampling.LANCZOS).getdata())
        bits = 0
        for y in range(8):
            for x in range(8):
                bits = (bits << 1) | (pixels[y * 9 + x] > pixels[y * 9 + x + 1])
    return {"sha256": hashlib.sha256(data).hexdigest(), "dhash": f"{bits:016x}"}


def duplicate(a, b):
    return (a["url"] == b["url"] or a["sha256"] == b["sha256"] or
            (int(a["dhash"], 16) ^ int(b["dhash"], 16)).bit_count() <= 5)


def fetch(url):
    # Provider image host allowlist: extend only after checking provider output.
    parts = urlsplit(url)
    if parts.scheme != "https" or parts.hostname != "static.cupid.travel" or parts.port not in (None, 443):
        raise ValueError("Unapproved photo host")
    with urlopen(url, timeout=20) as response:
        if urlsplit(response.url).hostname != parts.hostname:
            raise ValueError("Unexpected photo redirect")
        data = response.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("Photo too large")
    return data


def select(candidates, loader=fetch, cache_dir=None):
    selected, rejected = [], []
    for candidate in candidates:
        url = candidate["url"]
        try:
            data = loader(url)
            photo = {**candidate, **fingerprint(data)}
            if any(duplicate(photo, earlier) for earlier in selected):
                rejected.append({"url": url, "reason": "duplicate"})
                continue
            selected.append(photo)
            if cache_dir:
                Path(cache_dir).mkdir(parents=True, exist_ok=True)
                (Path(cache_dir) / f"photo-{len(selected)}.jpg").write_bytes(data)
            if len(selected) == MAX_PHOTOS:
                break
        except Exception as exc:
            rejected.append({"url": url, "reason": type(exc).__name__})
    if not selected:
        raise ValueError("No verified photos; keep the existing gallery")
    return {"verified_photos": selected, "rejected": rejected, "algorithm": ALGORITHM}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidates")
    parser.add_argument("output")
    parser.add_argument("--cache-dir")
    args = parser.parse_args()
    source = json.loads(Path(args.candidates).read_text())
    result = select(source["photos"], cache_dir=args.cache_dir)
    Path(args.output).write_text(json.dumps(result, indent=2))
    print(f"Selected {len(result['verified_photos'])}; rejected {len(result['rejected'])}")
