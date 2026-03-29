extends RefCounted
class_name TouchScrollHelper
## Вертикальный скролл по касанию при pointing/emulate_mouse_from_touch=false.
## Дочерние контролы внутри ScrollContainer не пробрасывают drag в скролл — дублируем через _input родителя меню.

var _touch_scroll: Dictionary = {} ## int (finger index) -> ScrollContainer
var _roots: Array[Node] = []


func reset() -> void:
	_touch_scroll.clear()


func add_root(root: Node) -> void:
	if root == null:
		return
	if not _roots.has(root):
		_roots.append(root)


func remove_root(root: Node) -> void:
	_roots.erase(root)
	reset()


func _collect_scrolls() -> Array[ScrollContainer]:
	var out: Array[ScrollContainer] = []
	for r in _roots:
		if r == null or not is_instance_valid(r):
			continue
		for n in r.find_children("*", "ScrollContainer", true, false):
			var sc := n as ScrollContainer
			if sc == null or out.has(sc):
				continue
			out.append(sc)
	return out


func _pick_scroll(global_pos: Vector2) -> ScrollContainer:
	var candidates: Array[ScrollContainer] = []
	for sc in _collect_scrolls():
		if not is_instance_valid(sc):
			continue
		if not sc.is_visible_in_tree():
			continue
		if not sc.get_global_rect().has_point(global_pos):
			continue
		candidates.append(sc)
	if candidates.is_empty():
		return null
	## При перекрытии — самый маленький прямоугольник (вложенный / колонка).
	var best: ScrollContainer = null
	var best_area := INF
	for sc in candidates:
		var a: float = sc.get_global_rect().get_area()
		if a < best_area:
			best_area = a
			best = sc
	return best


## Вернуть true, если жест нужно пометить handled (обычно ScreenDrag после начала скролла).
func consume_touch_scroll(event: InputEvent) -> bool:
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _touch_scroll.has(sd.index):
			return false
		var sc: ScrollContainer = _touch_scroll[sd.index]
		if sc == null or not is_instance_valid(sc) or not sc.is_visible_in_tree():
			_touch_scroll.erase(sd.index)
			return false
		sc.scroll_vertical -= int(sd.relative.y)
		return true
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var picked := _pick_scroll(st.position)
			if picked != null:
				_touch_scroll[st.index] = picked
			else:
				_touch_scroll.erase(st.index)
		else:
			_touch_scroll.erase(st.index)
		return false
	return false
