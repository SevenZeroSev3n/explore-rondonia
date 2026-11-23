"""Pure geometry for the geodata pipeline (ADR 0003). No I/O, fully unit-tested.

World convention (matches Godot 2D): x grows east, y grows SOUTH, units are metres until
scaled to pixels.
"""
from __future__ import annotations

import heapq
import math
from collections.abc import Iterable, Sequence

EARTH_RADIUS_M = 6_371_008.8

Point = tuple[float, float]


def project(lat: float, lon: float, origin: Point) -> Point:
    """Equirectangular projection around origin (lat0, lon0) -> metres (x east, y south).

    Distortion is negligible at the state scale (Rondônia spans ~4° of latitude) and the map is
    stylized anyway; what matters is that it is deterministic and keeps proportions.
    """
    lat0, lon0 = origin
    x = math.radians(lon - lon0) * EARTH_RADIUS_M * math.cos(math.radians(lat0))
    y = -math.radians(lat - lat0) * EARTH_RADIUS_M
    return (x, y)


def dist(a: Point, b: Point) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def polyline_length(points: Sequence[Point]) -> float:
    return sum(dist(points[i], points[i + 1]) for i in range(len(points) - 1))


def simplify(points: Sequence[Point], epsilon: float) -> list[Point]:
    """Ramer-Douglas-Peucker, iterative (long highways would blow the recursion limit)."""
    n = len(points)
    if n < 3:
        return list(points)
    keep = [False] * n
    keep[0] = keep[-1] = True
    stack = [(0, n - 1)]
    while stack:
        i0, i1 = stack.pop()
        a, b = points[i0], points[i1]
        best, best_i = -1.0, -1
        for i in range(i0 + 1, i1):
            d = point_segment_distance(points[i], a, b)
            if d > best:
                best, best_i = d, i
        if best > epsilon:
            keep[best_i] = True
            stack.append((i0, best_i))
            stack.append((best_i, i1))
    return [p for p, k in zip(points, keep) if k]


def point_segment_distance(p: Point, a: Point, b: Point) -> float:
    ax, ay = a
    dx, dy = b[0] - ax, b[1] - ay
    seg2 = dx * dx + dy * dy
    if seg2 == 0.0:
        return dist(p, a)
    t = max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - ay) * dy) / seg2))
    return dist(p, (ax + t * dx, ay + t * dy))


def build_graph(ways: Iterable[Sequence[int]], coords: dict[int, Point]) -> dict[int, list[tuple[int, float]]]:
    """Undirected graph over node ids; edges join consecutive nodes of each way.

    Direction is ignored on purpose: dual carriageways run metres apart, invisible at map scale.
    """
    graph: dict[int, list[tuple[int, float]]] = {}
    for way in ways:
        for u, v in zip(way, way[1:]):
            if u not in coords or v not in coords:
                continue
            w = dist(coords[u], coords[v])
            graph.setdefault(u, []).append((v, w))
            graph.setdefault(v, []).append((u, w))
    return graph


def largest_component(graph: dict[int, list[tuple[int, float]]]) -> set[int]:
    """Node ids of the biggest connected component (OSM leaves small detached fragments)."""
    seen: set[int] = set()
    best: set[int] = set()
    for root in graph:
        if root in seen:
            continue
        comp = {root}
        stack = [root]
        while stack:
            u = stack.pop()
            for v, _ in graph[u]:
                if v not in comp:
                    comp.add(v)
                    stack.append(v)
        seen |= comp
        if len(comp) > len(best):
            best = comp
    return best


def nearest_node(candidates: Iterable[int], coords: dict[int, Point], p: Point) -> int:
    return min(candidates, key=lambda n: dist(coords[n], p))


def shortest_path(graph: dict[int, list[tuple[int, float]]], start: int, goal: int) -> list[int]:
    """Dijkstra. Raises ValueError when goal is unreachable."""
    best = {start: 0.0}
    prev: dict[int, int] = {}
    heap = [(0.0, start)]
    while heap:
        d, u = heapq.heappop(heap)
        if u == goal:
            break
        if d > best.get(u, math.inf):
            continue
        for v, w in graph.get(u, ()):
            nd = d + w
            if nd < best.get(v, math.inf):
                best[v] = nd
                prev[v] = u
                heapq.heappush(heap, (nd, v))
    if goal != start and goal not in prev:
        raise ValueError(f"node {goal} unreachable from {start}")
    path = [goal]
    while path[-1] != start:
        path.append(prev[path[-1]])
    path.reverse()
    return path


def scale_for_drive_time(road_length_m: float, cruise_px_s: float, minutes: float) -> float:
    """Pixels per metre so that driving the whole road at cruise speed takes `minutes`."""
    if road_length_m <= 0:
        raise ValueError("road length must be positive")
    return cruise_px_s * minutes * 60.0 / road_length_m


def closest_on_polyline(points: Sequence[Point], p: Point) -> tuple[Point, int]:
    """Closest point on the polyline to p, and the index of the segment it lies on."""
    if len(points) < 2:
        raise ValueError("need at least two points")
    best_d, best_q, best_i = math.inf, points[0], 0
    for i, (a, b) in enumerate(zip(points, points[1:])):
        dx, dy = b[0] - a[0], b[1] - a[1]
        seg2 = dx * dx + dy * dy
        t = 0.0 if seg2 == 0 else max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / seg2))
        q = (a[0] + t * dx, a[1] + t * dy)
        d = dist(p, q)
        if d < best_d:
            best_d, best_q, best_i = d, q, i
    return best_q, best_i


def bearing_deg(frm: Point, to: Point) -> float:
    """Compass bearing from frm to to in degrees: 0 = north (-y), 90 = east, in [0, 360)."""
    return math.degrees(math.atan2(to[0] - frm[0], -(to[1] - frm[1]))) % 360.0


def distance_along(points: Sequence[Point], p: Point) -> tuple[float, float]:
    """(distance from p to the polyline, arc length along it at the closest point)."""
    best_d, best_s, s = math.inf, 0.0, 0.0
    for a, b in zip(points, points[1:]):
        seg = dist(a, b)
        if seg > 0:
            t = max(0.0, min(1.0, ((p[0] - a[0]) * (b[0] - a[0]) + (p[1] - a[1]) * (b[1] - a[1])) / (seg * seg)))
            q = (a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1]))
            d = dist(p, q)
            if d < best_d:
                best_d, best_s = d, s + t * seg
        s += seg
    return best_d, best_s
