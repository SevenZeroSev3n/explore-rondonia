import math
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "geo"))

import geomath as gm  # noqa: E402

ORIGIN = (-10.9, -62.8)


def test_origin_projects_to_zero():
    assert gm.project(*ORIGIN, ORIGIN) == pytest.approx((0.0, 0.0))


def test_north_is_negative_y_and_east_is_positive_x():
    x_n, y_n = gm.project(ORIGIN[0] + 0.1, ORIGIN[1], ORIGIN)
    x_e, y_e = gm.project(ORIGIN[0], ORIGIN[1] + 0.1, ORIGIN)
    assert y_n < 0 and x_n == pytest.approx(0.0)
    assert x_e > 0 and y_e == pytest.approx(0.0)


def test_one_degree_of_latitude_is_about_111_km():
    _, y = gm.project(ORIGIN[0] + 1.0, ORIGIN[1], ORIGIN)
    assert abs(y) == pytest.approx(111_195, rel=1e-3)


def test_longitude_shrinks_with_cos_latitude():
    x, _ = gm.project(ORIGIN[0], ORIGIN[1] + 1.0, ORIGIN)
    assert x == pytest.approx(111_195 * math.cos(math.radians(ORIGIN[0])), rel=1e-3)


def test_real_distance_vilhena_to_porto_velho_is_plausible():
    # About 700 km by road, but ~590 km in a straight line between the city centres.
    a = gm.project(-12.7369, -60.1466, ORIGIN)
    b = gm.project(-8.7495, -63.8735, ORIGIN)
    assert 560_000 < gm.dist(a, b) < 620_000


def test_simplify_keeps_endpoints_and_drops_collinear_points():
    pts = [(0, 0), (1, 0.01), (2, 0), (3, 0.01), (4, 0)]
    assert gm.simplify(pts, 0.5) == [(0, 0), (4, 0)]


def test_simplify_keeps_real_corners():
    pts = [(0, 0), (5, 0), (5, 5)]
    assert gm.simplify(pts, 0.5) == pts


def test_simplify_handles_long_inputs_without_recursion():
    pts = [(float(i), math.sin(i / 10.0)) for i in range(20_000)]
    out = gm.simplify(pts, 0.05)
    assert out[0] == pts[0] and out[-1] == pts[-1]
    assert 2 < len(out) < len(pts)


def test_point_segment_distance():
    assert gm.point_segment_distance((5, 3), (0, 0), (10, 0)) == pytest.approx(3)
    assert gm.point_segment_distance((-4, 3), (0, 0), (10, 0)) == pytest.approx(5)
    assert gm.point_segment_distance((1, 1), (0, 0), (0, 0)) == pytest.approx(math.sqrt(2))


def _square_graph():
    coords = {1: (0, 0), 2: (10, 0), 3: (10, 10), 4: (0, 10), 9: (100, 100)}
    ways = [[1, 2, 3], [3, 4, 1], [9, 404]]  # 404 has no coordinates: ignored
    return gm.build_graph(ways, coords), coords


def test_shortest_path_picks_the_short_side():
    graph, _ = _square_graph()
    assert gm.shortest_path(graph, 1, 2) == [1, 2]
    assert gm.shortest_path(graph, 2, 4) in ([2, 1, 4], [2, 3, 4])


def test_shortest_path_to_itself():
    graph, _ = _square_graph()
    assert gm.shortest_path(graph, 1, 1) == [1]


def test_unreachable_goal_raises():
    coords = {1: (0, 0), 2: (1, 0), 3: (5, 5), 4: (6, 5)}
    graph = gm.build_graph([[1, 2], [3, 4]], coords)
    with pytest.raises(ValueError):
        gm.shortest_path(graph, 1, 4)


def test_largest_component_ignores_detached_fragments():
    coords = {1: (0, 0), 2: (1, 0), 3: (2, 0), 7: (50, 50), 8: (51, 50)}
    graph = gm.build_graph([[1, 2, 3], [7, 8]], coords)
    assert gm.largest_component(graph) == {1, 2, 3}


def test_nearest_node_only_among_candidates():
    coords = {1: (0, 0), 2: (100, 0)}
    assert gm.nearest_node([2], coords, (1, 0)) == 2


def test_scale_for_drive_time():
    # 700 km at 90 px/s in 8 min -> 43_200 px -> 0.0617 px/m
    assert gm.scale_for_drive_time(700_000, 90, 8) == pytest.approx(43_200 / 700_000)
    with pytest.raises(ValueError):
        gm.scale_for_drive_time(0, 90, 8)


def test_closest_on_polyline():
    line = [(0, 0), (10, 0), (10, 10)]
    q, i = gm.closest_on_polyline(line, (12, 5))
    assert q == pytest.approx((10, 5)) and i == 1
    q, i = gm.closest_on_polyline(line, (-3, -1))
    assert q == pytest.approx((0, 0)) and i == 0
    with pytest.raises(ValueError):
        gm.closest_on_polyline([(0, 0)], (1, 1))


def test_bearing_deg():
    assert gm.bearing_deg((0, 0), (0, -5)) == pytest.approx(0)      # north
    assert gm.bearing_deg((0, 0), (5, 0)) == pytest.approx(90)      # east
    assert gm.bearing_deg((0, 0), (0, 5)) == pytest.approx(180)     # south
    assert gm.bearing_deg((0, 0), (-5, 0)) == pytest.approx(270)    # west


def test_distance_along():
    line = [(0, 0), (10, 0), (10, 10)]
    d, s = gm.distance_along(line, (12, 5))
    assert d == pytest.approx(2) and s == pytest.approx(15)
