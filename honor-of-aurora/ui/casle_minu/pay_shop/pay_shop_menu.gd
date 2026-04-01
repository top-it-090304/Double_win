extends Control

## База API оплаты (пустая строка = мгновенная покупка без сервера, затычка без backend).
@export var payment_api_base_url: String = ""

const _POLL_INTERVAL_SEC := 2.0
const _POLL_TIMEOUT_SEC := 120.0

var _touch_scroll_helper := TouchScrollHelper.new()

## Иконки пакетов по порядку в BalanceConfig.PREMIUM_ORE_PACKS: 1, 6, 2, 8.
const _PACK_ROW_TEXTURES := {
	"starter": preload("res://Asets/Руда/1.png"),
	"adventurer": preload("res://Asets/Руда/6.png"),
	"commander": preload("res://Asets/Руда/2.png"),
	"warlord": preload("res://Asets/Руда/8.png"),
}
const _ORE_ICON_MAIN := preload("res://Asets/Руда/1.png")

const _X_USER_ID_FILE := "user://payment_x_user_id.txt"

enum _HttpPending { NONE, CREATE, STATUS }
var _http: HTTPRequest
var _poll_timer: Timer
var _http_pending: _HttpPending = _HttpPending.NONE
var _poll_order_id: int = -1
var _pending_pack_id: String = ""
var _poll_deadline_msec: int = 0
var _purchase_flow_active: bool = false


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


func _ready() -> void:
	_touch_scroll_helper.add_root(self)
	set_process_input(true)
	if not visibility_changed.is_connected(_on_payshop_visibility_for_touch_scroll):
		visibility_changed.connect(_on_payshop_visibility_for_touch_scroll)
	Events.ore_changed.connect(_on_ore_changed)
	Events.premium_ore_pack_purchased.connect(_on_pack_purchased)
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_http_request_completed)
	_poll_timer = Timer.new()
	_poll_timer.wait_time = _POLL_INTERVAL_SEC
	_poll_timer.one_shot = false
	_poll_timer.timeout.connect(_on_poll_timer_timeout)
	add_child(_poll_timer)
	_rebuild_rows()
	_refresh_summary()


func _exit_tree() -> void:
	if Events.ore_changed.is_connected(_on_ore_changed):
		Events.ore_changed.disconnect(_on_ore_changed)
	if Events.premium_ore_pack_purchased.is_connected(_on_pack_purchased):
		Events.premium_ore_pack_purchased.disconnect(_on_pack_purchased)
	_abort_payment_flow(false)


func reset_payshop_menu_state() -> void:
	_abort_payment_flow(false)
	_rebuild_rows()
	_refresh_summary()


func _on_ore_changed(_value: int) -> void:
	if visible:
		_refresh_summary()


func _on_pack_purchased(_pack_id: String, _ore_added: int) -> void:
	_refresh_summary()


func _refresh_summary() -> void:
	var subtitle := get_node_or_null("PayShopPanel/PayShopSubtitle") as Label
	if subtitle:
		subtitle.text = "Премиум-магазин Сердцевины. Покупки: %d · Куплено Сердцевины: %d · На балансе: %d" % [
			SaveManager.premium_ore_purchase_count,
			SaveManager.premium_ore_purchased_total,
			SaveManager.ore_count,
		]


func _payment_flow_label() -> Label:
	return get_node_or_null("PayShopPanel/PaymentFlowLabel") as Label


func _set_payment_flow_message(text: String) -> void:
	var lbl := _payment_flow_label()
	if lbl == null:
		return
	lbl.visible = not text.is_empty()
	lbl.text = text


func _rebuild_rows() -> void:
	var rows := get_node_or_null("PayShopPanel/Scroll/Rows") as VBoxContainer
	if rows == null:
		return
	for c in rows.get_children():
		c.queue_free()
	for pack_id in BalanceConfig.get_premium_ore_pack_ids():
		var pack := BalanceConfig.get_premium_ore_pack(pack_id)
		if pack.is_empty():
			continue
		rows.add_child(_make_pack_row(pack_id, pack))
	_apply_rows_buy_enabled(not _purchase_flow_active)


func _apply_rows_buy_enabled(enabled: bool) -> void:
	var rows := get_node_or_null("PayShopPanel/Scroll/Rows") as VBoxContainer
	if rows == null:
		return
	for row in rows.get_children():
		if row.get_child_count() < 1:
			continue
		var last := row.get_child(row.get_child_count() - 1)
		if last is Button:
			(last as Button).disabled = not enabled


func _make_pack_row(pack_id: String, pack: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(56, 56)
	icon_rect.texture = _PACK_ROW_TEXTURES.get(pack_id, _ORE_ICON_MAIN)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon_rect)

	var info := Label.new()
	var ore := int(pack.get("ore", 0))
	var bonus := int(pack.get("bonus_ore", 0))
	var total := ore + bonus
	info.text = "%s · %d + %d бонус = %d Сердцевины" % [String(pack.get("title", pack_id)), ore, bonus, total]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(info)

	var price := Label.new()
	price.text = String(pack.get("price_label", "0 ₽"))
	price.custom_minimum_size = Vector2(92, 0)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(price)

	var btn := Button.new()
	btn.text = "Купить"
	btn.custom_minimum_size = Vector2(132, 48)
	btn.pressed.connect(_on_buy_pack_pressed.bind(pack_id))
	row.add_child(btn)
	return row


func _api_base_normalized() -> String:
	return str(payment_api_base_url).strip_edges().rstrip("/")


func _api_error_text(data: Dictionary) -> String:
	var d: Variant = data.get("detail")
	if d is String:
		return d as String
	if d is Dictionary:
		if (d as Dictionary).has("error"):
			return str((d as Dictionary).get("error"))
		return JSON.stringify(d)
	if data.has("error"):
		return str(data.get("error"))
	return JSON.stringify(data)


func _persisted_x_user_id() -> String:
	if FileAccess.file_exists(_X_USER_ID_FILE):
		var s := FileAccess.get_file_as_string(_X_USER_ID_FILE).strip_edges()
		if not s.is_empty():
			return s.substr(0, 64)
	var id := "h0_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var f := FileAccess.open(_X_USER_ID_FILE, FileAccess.WRITE)
	if f:
		f.store_string(id)
		f.close()
	return id.substr(0, 64)


func _on_buy_pack_pressed(pack_id: String) -> void:
	SoundManager.play_ui_button()
	if _api_base_normalized().is_empty():
		GameplayFacade.purchase_premium_ore_pack(pack_id)
		return
	var pack := BalanceConfig.get_premium_ore_pack(pack_id)
	var sku := str(pack.get("payment_sku", "")).strip_edges()
	if sku.is_empty():
		_set_payment_flow_message("Нет серверного SKU для этого пакета.")
		return
	_start_server_purchase(pack_id, sku)


func _start_server_purchase(pack_id: String, sku: String) -> void:
	if _http_pending != _HttpPending.NONE:
		return
	_purchase_flow_active = true
	_pending_pack_id = pack_id
	_poll_order_id = -1
	_apply_rows_buy_enabled(false)
	_set_payment_flow_message("Создаём платёж…")
	var base := _api_base_normalized()
	var url := "%s/payments/create" % base
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"X-User-Id: %s" % _persisted_x_user_id(),
	])
	var body := JSON.stringify({"sku": sku})
	_http_pending = _HttpPending.CREATE
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err == ERR_BUSY:
		_http_pending = _HttpPending.NONE
		_purchase_flow_active = false
		_apply_rows_buy_enabled(true)
		_set_payment_flow_message("Подождите завершения запроса или нажмите «Назад» и попробуйте снова.")
		return
	if err != OK:
		_http_pending = _HttpPending.NONE
		_purchase_flow_active = false
		_apply_rows_buy_enabled(true)
		_set_payment_flow_message("Сеть: не удалось отправить запрос (%d)." % err)


func _request_order_status() -> void:
	if _poll_order_id < 0 or _http_pending != _HttpPending.NONE:
		return
	var base := _api_base_normalized()
	var url := "%s/payments/%d/status" % [base, _poll_order_id]
	var headers := PackedStringArray([
		"X-User-Id: %s" % _persisted_x_user_id(),
	])
	_http_pending = _HttpPending.STATUS
	var err := _http.request(url, headers, HTTPClient.METHOD_GET)
	if err == ERR_BUSY:
		_http_pending = _HttpPending.NONE
		return
	if err != OK:
		_http_pending = _HttpPending.NONE
		_abort_payment_flow(true)
		_set_payment_flow_message("Сеть: ошибка опроса статуса (%d)." % err)


func _on_poll_timer_timeout() -> void:
	if not _purchase_flow_active or _poll_order_id < 0:
		_poll_timer.stop()
		return
	if Time.get_ticks_msec() >= _poll_deadline_msec:
		_poll_timer.stop()
		_abort_payment_flow(true)
		_set_payment_flow_message("Время ожидания оплаты истекло. Проверьте платёж или попробуйте снова.")
		return
	_request_order_status()


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var op := _http_pending
	_http_pending = _HttpPending.NONE
	if result != HTTPRequest.RESULT_SUCCESS:
		if op == _HttpPending.CREATE:
			_abort_payment_flow(true)
			_set_payment_flow_message("Ошибка сети при создании платежа.")
		elif op == _HttpPending.STATUS:
			## Следующий тик таймера повторит опрос.
			pass
		return
	var text := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) != OK:
		if op == _HttpPending.CREATE:
			_abort_payment_flow(true)
			_set_payment_flow_message("Некорректный ответ сервера.")
		return
	var data: Variant = json.data
	if data is Dictionary:
		_handle_payment_json_response(op, response_code, data)
	else:
		if op == _HttpPending.CREATE:
			_abort_payment_flow(true)
			_set_payment_flow_message("Некорректный ответ сервера.")


func _handle_payment_json_response(op: _HttpPending, response_code: int, data: Dictionary) -> void:
	if op == _HttpPending.CREATE:
		if response_code != 200:
			var err_msg := _api_error_text(data)
			_abort_payment_flow(true)
			_set_payment_flow_message("Платёж не создан: %s" % err_msg)
			return
		var oid := int(data.get("order_id", -1))
		var pay_url := str(data.get("payment_url", "")).strip_edges()
		if oid < 0 or pay_url.is_empty():
			_abort_payment_flow(true)
			_set_payment_flow_message("Сервер не вернул order_id или payment_url.")
			return
		_poll_order_id = oid
		_poll_deadline_msec = Time.get_ticks_msec() + int(_POLL_TIMEOUT_SEC * 1000.0)
		_set_payment_flow_message("Откройте страницу оплаты. Ожидаем подтверждение…")
		OS.shell_open(pay_url)
		_poll_timer.start()
		return
	if op == _HttpPending.STATUS:
		if response_code == 404:
			_poll_timer.stop()
			_abort_payment_flow(true)
			_set_payment_flow_message("Заказ не найден или доступ запрещён.")
			return
		if response_code != 200:
			return
		var st := str(data.get("payment_status", "")).strip_edges()
		var granted := bool(data.get("granted", false))
		## Успех: сервер подтвердил выдачу по заказу.
		if st == "paid" and granted:
			_poll_timer.stop()
			var pack_id := _pending_pack_id
			_abort_payment_flow(false)
			_set_payment_flow_message("")
			if not pack_id.is_empty():
				GameplayFacade.purchase_premium_ore_pack(pack_id)
			return
		if st == "paid" and not granted:
			_set_payment_flow_message("Оплата получена, ждём выдачу на сервере…")
			return
		if st in ["failed", "cancelled", "refunded", "partially_refunded"]:
			_poll_timer.stop()
			_abort_payment_flow(true)
			_set_payment_flow_message("Платёж: %s. Покупка не завершена." % st)
			return
		_set_payment_flow_message("Ожидаем оплату… (%s)" % st)


func _abort_payment_flow(clear_message: bool) -> void:
	_poll_timer.stop()
	_http_pending = _HttpPending.NONE
	if is_instance_valid(_http):
		_http.cancel_request()
	_purchase_flow_active = false
	_poll_order_id = -1
	_pending_pack_id = ""
	_apply_rows_buy_enabled(true)
	if clear_message:
		_set_payment_flow_message("")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _touch_scroll_helper.consume_touch_scroll(event):
		get_viewport().set_input_as_handled()


func _on_payshop_visibility_for_touch_scroll() -> void:
	if not visible:
		_touch_scroll_helper.reset()


func _on_back_pressed() -> void:
	_touch_scroll_helper.reset()
	SoundManager.play_ui_button()
	_abort_payment_flow(true)
	var hud := get_hud()
	if hud and hud.has_method("hide_payshop_menu"):
		hud.hide_payshop_menu()
