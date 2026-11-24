class_name WebPhoto
extends RefCounted
## Real photos stay sharp on the web build (ADR 0005): the game renders at 480x270
## and scales up, which would pixelate a photo, so on the web the photo is an HTML
## <img> laid exactly over its frame in the game. Elsewhere this does nothing and
## the in-game TextureRect shows the (downscaled) photo instead.

const ELEMENT_ID := "explore-rondonia-photo"

static var _shown_file := ""


static func available() -> bool:
	return OS.has_feature("web")


## rect: the photo frame in WINDOW pixels (viewport rect through the stretch transform).
static func show(file: String, rect: Rect2) -> void:
	if not available():
		return
	var src := "null"
	if file != _shown_file:
		# Exports pack only the imported texture, not the original JPEG: re-encode the
		# texture's image once (full resolution) and hand it to the page.
		var tex: Texture2D = load(file)
		if tex == null:
			push_warning("photo missing: %s" % file)
			return
		var bytes := tex.get_image().save_jpg_to_buffer(0.9)
		src = JSON.stringify("data:image/jpeg;base64," + Marshalls.raw_to_base64(bytes))
		_shown_file = file
	JavaScriptBridge.eval(_script(src, rect))


static func hide() -> void:
	if not available():
		return
	JavaScriptBridge.eval("(function(){var i=document.getElementById('%s');if(i)i.style.display='none';})();" % ELEMENT_ID)


## Window-pixel rect of a control (undoes nothing: applies the root stretch transform).
static func window_rect(control: Control) -> Rect2:
	var xf := control.get_tree().root.get_final_transform()
	var r := control.get_global_rect()
	return Rect2(xf * r.position, xf.basis_xform(r.size))


static func _script(src_json: String, rect: Rect2) -> String:
	# The canvas may be CSS-scaled (devicePixelRatio): convert canvas pixels to CSS pixels.
	return """(function(src,x,y,w,h){
  var c=document.querySelector('canvas'); if(!c) return;
  var r=c.getBoundingClientRect(), sx=r.width/c.width, sy=r.height/c.height;
  var i=document.getElementById('%s');
  if(!i){ i=document.createElement('img'); i.id='%s';
    i.style.position='fixed'; i.style.objectFit='cover'; i.style.pointerEvents='none';
    i.style.zIndex='10'; document.body.appendChild(i); }
  if(src) i.src=src;
  i.style.left=(r.left+x*sx)+'px'; i.style.top=(r.top+y*sy)+'px';
  i.style.width=(w*sx)+'px'; i.style.height=(h*sy)+'px'; i.style.display='block';
})(%s,%f,%f,%f,%f);""" % [ELEMENT_ID, ELEMENT_ID, src_json, rect.position.x, rect.position.y, rect.size.x, rect.size.y]
