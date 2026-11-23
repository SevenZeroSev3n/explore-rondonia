"""Download the raw geodata for the state map into tools/cache/ (git-ignored). ADR 0003.

Sources:
  - IBGE malhas API: Rondônia state border (public data)
  - OpenStreetMap via Overpass: BR-364 ways, major rivers, city/town nodes (ODbL)

Usage:
  python3 tools/geo/fetch.py [--force]
"""
from __future__ import annotations

import argparse
import json
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

CACHE = Path(__file__).resolve().parent.parent / "cache"
USER_AGENT = "explore-rondonia-geodata/0.1"
OVERPASS = "https://overpass-api.de/api/interpreter"
OVERPASS_MIRROR = "https://overpass.private.coffee/api/interpreter"
IBGE_STATE = (
    "https://servicodados.ibge.gov.br/api/v3/malhas/estados/RO"
    "?formato=application/vnd.geo%2Bjson&qualidade=intermediaria"
)

RO_AREA = 'area["ISO3166-2"="BR-RO"]->.ro;'

# Rivers worth drawing on the state map (crossed by or close to BR-364, or the state border).
RIVERS = [
    "Rio Madeira", "Rio Machado", "Rio Ji-Paraná", "Rio Jamari", "Rio Candeias", "Rio Jaru",
    "Rio Urupá", "Rio Pimenta Bueno", "Rio Comemoração", "Rio Barão de Melgaço", "Rio Mamoré",
    "Rio Guaporé", "Rio Machadinho", "Rio Preto", "Rio Abunã",
]

QUERIES = {
    "br364.json": f"""
        [out:json][timeout:180];
        {RO_AREA}
        way["highway"]["ref"~"(^|;)\\s*BR-364\\s*(;|$)"](area.ro)->.road;
        .road out body;
        .road >;
        out skel qt;
    """,
    "rivers.json": f"""
        [out:json][timeout:180];
        {RO_AREA}
        way["waterway"="river"]["name"~"^({'|'.join(RIVERS)})$"](area.ro);
        out geom qt;
    """,
    "places.json": f"""
        [out:json][timeout:120];
        {RO_AREA}
        node["place"~"^(city|town)$"](area.ro);
        out;
    """,
}


def get(url: str, data: bytes | None = None) -> bytes:
    req = urllib.request.Request(url, data=data, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def overpass(body: bytes) -> bytes:
    """Public Overpass instances often answer 429/502/504; retry, then try the mirror."""
    last: Exception | None = None
    for url in (OVERPASS, OVERPASS_MIRROR):
        for attempt in range(3):
            try:
                return get(url, body)
            except urllib.error.HTTPError as e:
                if e.code not in (429, 502, 503, 504):
                    raise
                last = e
                time.sleep(10 * (attempt + 1))
    raise RuntimeError(f"Overpass unavailable: {last}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--force", action="store_true", help="download even if cached")
    force = p.parse_args().force
    CACHE.mkdir(parents=True, exist_ok=True)

    jobs = [("ro_state.geojson", lambda: get(IBGE_STATE))]
    for name, q in QUERIES.items():
        body = urllib.parse.urlencode({"data": q}).encode()
        jobs.append((name, lambda body=body: overpass(body)))

    for name, fetch in jobs:
        dst = CACHE / name
        if dst.exists() and not force:
            print(f"cached  {dst.name}")
            continue
        raw = fetch()
        json.loads(raw)  # fail loudly on an error page
        dst.write_bytes(raw)
        print(f"fetched {dst.name} ({len(raw) / 1e6:.1f} MB)")
        time.sleep(2)  # be gentle with the public Overpass instance


if __name__ == "__main__":
    main()
