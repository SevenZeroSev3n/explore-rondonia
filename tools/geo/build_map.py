"""Build the layer-1 state map JSON the game reads (ADR 0003).

Reads tools/cache/ (see fetch.py) and writes game/data/geo/state_map.json:
  - BR-364 from Vilhena to Porto Velho as one ordered polyline, in pixels
  - rivers, the state border, towns along the road (MVP stamp cities flagged)
  - the scale, chosen so the whole road takes TARGET_MINUTES at CRUISE_PX_S

Usage:
  python3 tools/geo/build_map.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import geomath as gm  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent.parent
CACHE = ROOT / "tools/cache"
OUT = ROOT / "game/data/geo/state_map.json"
PLACES = ROOT / "game/data/places"

# Must match VehicleModel.max_speed in game/scripts/vehicle/vehicle_model.gd.
CRUISE_PX_S = 90.0
TARGET_MINUTES = 8.0
ORIGIN = (-10.9, -62.8)          # (lat, lon), roughly the state's middle
ROAD_FROM, ROAD_TO = "Vilhena", "Porto Velho"
STAMP_CITIES = ["Vilhena", "Ji-Paraná", "Ariquemes", "Porto Velho"]
TOWN_MAX_ROAD_DISTANCE_M = 4000  # towns farther than this from BR-364 are left out
ROAD_EPSILON_PX = 1.0
RIVER_EPSILON_PX = 3.0
BORDER_EPSILON_PX = 4.0

# Shown as-is in both languages: names and licences only, no prose to translate.
ATTRIBUTION = [
    "© OpenStreetMap contributors (ODbL)",
    "IBGE — Malhas territoriais",
]


def load(name: str) -> dict:
    return json.loads((CACHE / name).read_text(encoding="utf-8"))


def rnd(points):
    return [[round(x, 1), round(y, 1)] for x, y in points]


def main() -> None:
    road_raw = load("br364.json")["elements"]
    coords = {e["id"]: gm.project(e["lat"], e["lon"], ORIGIN) for e in road_raw if e["type"] == "node"}
    ways = [e["nodes"] for e in road_raw if e["type"] == "way"]
    graph = gm.build_graph(ways, coords)

    places = {
        e["tags"]["name"]: gm.project(e["lat"], e["lon"], ORIGIN)
        for e in load("places.json")["elements"]
        if "name" in e.get("tags", {})
    }
    main_road = gm.largest_component(graph)
    start = gm.nearest_node(main_road, coords, places[ROAD_FROM])
    goal = gm.nearest_node(main_road, coords, places[ROAD_TO])
    road_m = [coords[n] for n in gm.shortest_path(graph, start, goal)]
    length_m = gm.polyline_length(road_m)
    scale = gm.scale_for_drive_time(length_m, CRUISE_PX_S, TARGET_MINUTES)

    def px(points):
        return [(x * scale, y * scale) for x, y in points]

    road_px = gm.simplify(px(road_m), ROAD_EPSILON_PX)

    towns = []
    for name, p in places.items():
        d, s = gm.distance_along(road_m, p)
        if d <= TOWN_MAX_ROAD_DISTANCE_M or name in STAMP_CITIES:
            x, y = p[0] * scale, p[1] * scale
            (rx, ry), seg = gm.closest_on_polyline(road_px, (x, y))
            towns.append({
                "name": name,
                "pos": [round(x, 1), round(y, 1)],
                "road_pos": [round(rx, 1), round(ry, 1)],   # where stamps trigger and teleports land
                "road_seg": seg,                            # segment index, for the heading
                "road_km": round(s / 1000.0, 1),
                "stamp": name in STAMP_CITIES,
            })
    towns.sort(key=lambda t: t["road_km"])
    missing = set(STAMP_CITIES) - {t["name"] for t in towns}
    if missing:
        raise SystemExit(f"stamp cities missing from OSM places: {missing}")

    rivers = []
    for e in load("rivers.json")["elements"]:
        pts = [gm.project(g["lat"], g["lon"], ORIGIN) for g in e.get("geometry", [])]
        pts = gm.simplify(px(pts), RIVER_EPSILON_PX)
        if len(pts) >= 2:
            rivers.append({"name": e["tags"]["name"], "points": rnd(pts)})

    # Photo spots on layer 1 (ADR 0008). By default the player photographs a spot from the side
    # facing the road, the way they arrive; a place file can override view_from_deg.
    spots = []
    for f in sorted(PLACES.glob("*.json")):
        place = json.loads(f.read_text(encoding="utf-8"))
        if place.get("layer") != 1 or "latlon" not in place:
            continue
        sx, sy = gm.project(*place["latlon"], ORIGIN)
        spot = (sx * scale, sy * scale)
        road_pt, _ = gm.closest_on_polyline(road_px, spot)
        spots.append({
            "id": place["id"],
            "pos": [round(spot[0], 1), round(spot[1], 1)],
            "view_from_deg": round(place.get("view_from_deg", gm.bearing_deg(spot, road_pt)), 1),
        })

    state = load("ro_state.geojson")["features"][0]["geometry"]
    ring = state["coordinates"][0] if state["type"] == "Polygon" else max(
        (poly[0] for poly in state["coordinates"]), key=len)
    border = gm.simplify(px([gm.project(lat, lon, ORIGIN) for lon, lat in ring]), BORDER_EPSILON_PX)

    out = {
        "version": 1,
        "origin_latlon": list(ORIGIN),
        "px_per_m": scale,
        "road": {
            "name": "BR-364",
            "from": ROAD_FROM,
            "to": ROAD_TO,
            "length_km": round(length_m / 1000.0, 1),
            "points": rnd(road_px),
        },
        "towns": towns,
        "spots": spots,
        "rivers": rivers,
        "border": rnd(border),
        "attribution": ATTRIBUTION,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(
        f"wrote {OUT.relative_to(ROOT)}: BR-364 {length_m / 1000:.0f} km -> {len(road_px)} pts, "
        f"{scale:.4f} px/m ({1 / scale:.1f} m/px), {len(towns)} towns, {len(rivers)} river ways, "
        f"{len(spots)} photo spots, border {len(border)} pts, {OUT.stat().st_size / 1e3:.0f} kB"
    )


if __name__ == "__main__":
    main()
