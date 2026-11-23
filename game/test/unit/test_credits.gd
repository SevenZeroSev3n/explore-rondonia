extends GutTest


func test_source_hosts_are_unique_sorted_and_without_www() -> void:
	var c := PlaceCatalog.new()
	c.places = {
		"a": {"sources": ["https://www.example.org/x", "https://b.example.com/y"]},
		"b": {"sources": ["http://example.org/z"]},
	}
	assert_eq(Credits.source_hosts(c), PackedStringArray(["b.example.com", "example.org"]))


func test_lines_include_licences_engine_map_data_and_sources() -> void:
	var t := func(key: String) -> String: return {"CREDITS_CODE": "code", "CREDITS_ENGINE": "engine", "CREDITS_SOURCES": "src: %s"}[key]
	var lines := Credits.lines(t, PackedStringArray(["© OSM"]), PackedStringArray(["a.org", "b.org"]))
	assert_eq(lines, PackedStringArray(["code", "engine", "© OSM", "src: a.org, b.org"]))


func test_shipped_credits_name_openstreetmap_and_ibge() -> void:
	var m := StateMapData.load_file()
	var text := "\n".join(m.attribution)
	assert_string_contains(text, "OpenStreetMap")
	assert_string_contains(text, "IBGE")
