class_name Credits
extends RefCounted
## What the credits screen lists (ADR 0006/0007): licences, the engine, map data
## attribution and the sites the place texts are based on.


## Unique hostnames of every place's sources, sorted.
static func source_hosts(catalog: PlaceCatalog) -> PackedStringArray:
	var hosts: PackedStringArray = []
	for id in catalog.places:
		for url in catalog.sources_of(id):
			var host := url.trim_prefix("https://").trim_prefix("http://").get_slice("/", 0).to_lower()
			host = host.trim_prefix("www.")
			if not host.is_empty() and not hosts.has(host):
				hosts.append(host)
	hosts.sort()
	return hosts


## "Photo, <place>: <author> (<licence>)" for every real photo, sorted by place id.
static func photo_lines(t: Callable, catalog: PlaceCatalog, locale: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var ids: Array = catalog.places.keys()
	ids.sort()
	for id in ids:
		for photo in catalog.photos_of(id):
			out.append(t.call("CREDITS_PHOTO") % [catalog.name_of(id, locale), photo.get("author", "?"), photo.get("license", "?")])
	return out


## The credit lines in display order; `t` translates a string key (tr).
static func lines(t: Callable, map_attribution: PackedStringArray, hosts: PackedStringArray,
		photos: PackedStringArray = []) -> PackedStringArray:
	var out: PackedStringArray = [t.call("CREDITS_CODE"), t.call("CREDITS_ENGINE"), t.call("CREDITS_FONT")]
	out.append_array(map_attribution)
	out.append_array(photos)
	out.append(t.call("CREDITS_SOURCES") % ", ".join(hosts))
	return out
