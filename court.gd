extends Control
## Turn-based volleyball, with public information and no random rolls.

enum Phase { RECEIVE, RETURN, POINT, MATCH }
const GOAL := 5
const LANES := ["LEFT", "MIDDLE", "RIGHT"]
# incoming lane, driven ball, rival guard. A covered return invites a counter.
const SERVES := [[0, true, 2], [1, false, 1], [2, true, 1],
	[0, false, 0], [1, true, 1], [2, false, 2],
	[0, true, 0], [1, false, 2], [2, true, 2]]
const BACK := Color("#122438")
const SKY := Color("#192e46")
const CREAM := Color("#ffeace")
const MUTE := Color("#b9cad8")
const GOLD := Color("#ffc97a")
const TEAL := Color("#9af2db")
const CORAL := Color("#ff9f92")
const COURT := Rect2(43, 158, 700, 377)
const NET_Y := 340.0
const RIVAL_Y := 253.0
const HOME_Y := 448.0

var phase: Phase
var points := Vector2i.ZERO
var rally := 0
var contacts := 0
var incoming := 0
var driven := false
var guard := 0
var gather_lane := -1
var message := ""
var history: Array[String] = []
var decisions: Array[Button] = []
var restart: Button
var score: Label
var header: Label
var detail: Label
var context: Label
var summary: Label
var log_view: Label
var status: Label

func _ready() -> void:
	theme = Theme.new()
	theme.default_font_size = 18
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": Color("#284760"), "hover": Color("#365a73"),
			"pressed": Color("#43677e"), "disabled": Color("#21354b"), "focus": Color.TRANSPARENT}[state]
		box.border_color = GOLD if state == "focus" or state == "hover" else Color("#496375")
		box.set_border_width_all(2 if state == "focus" else 1)
		box.set_corner_radius_all(7)
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", Color("#92a6b6"))
	_label("TURN-BASED VOLLEYBALL  /  FIRST TO FIVE", Vector2(42, 21), 15, GOLD)
	_label("Sideline Signal", Vector2(37, 40), 47, CREAM)
	score = _label("", Vector2(763, 39), 25, CREAM)
	_label("RIVALS  /  GUARD SHOWN", Vector2(45, 129), 16, CORAL)
	_label("YOU  /  THREE PLAYERS", Vector2(45, 542), 16, TEAL)
	_label("RALLY CALLS", Vector2(43, 590), 16, GOLD)
	log_view = _label("", Vector2(43, 617), 16, MUTE)
	header = _label("", Vector2(790, 154), 23, CREAM)
	detail = _label("", Vector2(790, 196), 17, CREAM, 347)
	context = _label("", Vector2(790, 254), 15, MUTE, 347)
	status = _label("", Vector2(790, 469), 16, TEAL, 347)
	summary = _label("Mouse or keyboard. No timer.", Vector2(790, 565), 16, MUTE, 347)
	restart = _button("Restart match  [R]", Rect2(788, 630, 361, 44), _reset)
	for i in range(3):
		decisions.append(_button("", Rect2(788, 314 + 49 * i, 361, 41), _choose.bind(i)))
	_reset()

func _label(value: String, pos: Vector2, size_px: int, color: Color, width := -1) -> Label:
	var l := Label.new()
	l.text = value
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size_px)
	if width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size.x = width
	add_child(l)
	return l

func _button(value: String, bounds: Rect2, activated: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.position = bounds.position
	button.size = bounds.size
	button.pressed.connect(activated)
	add_child(button)
	return button

func _reset() -> void:
	points = Vector2i.ZERO
	rally = 0
	history.clear()
	_serve()

func _serve() -> void:
	var serve: Array = SERVES[rally % SERVES.size()]
	incoming = serve[0]
	driven = serve[1]
	guard = serve[2]
	contacts = 0
	gather_lane = -1
	phase = Phase.RECEIVE
	message = "Rally %d. Read the landing lane." % (rally + 1)
	_note("Rivals serve %s to %s." % [_ball_kind().to_lower(), LANES[incoming].to_lower()])
	_refresh()

func _note(line: String) -> void:
	history.append(line)

func _ball_kind() -> String:
	return "DRIVEN" if driven else "FLOAT"

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return
	var handled := true
	match event.keycode:
		KEY_R: _reset()
		KEY_S:
			if phase == Phase.RECEIVE: _choose(0)
		KEY_G:
			if phase == Phase.RECEIVE: _choose(1)
		KEY_1, KEY_2, KEY_3:
			if phase == Phase.RETURN: _choose(event.keycode - KEY_1)
		KEY_SPACE, KEY_ENTER:
			if phase == Phase.POINT: _choose(0)
			else: handled = false
		_: handled = false
	if handled:
		get_viewport().set_input_as_handled()

func _choose(i: int) -> void:
	match phase:
		Phase.RECEIVE:
			if i > 1: return
			if i == 0 and driven:
				_point(false, "Driven ball breaks through spread coverage.")
				return
			gather_lane = incoming if i == 1 else -1
			_note("Gather digs the ball." if i == 1 else "Spread receives cleanly.")
			phase = Phase.RETURN
			message = "Your team is bunched; far returns are closed." if i == 1 else "Clean receive. All three lanes are in reach."
		Phase.RETURN:
			if not _reachable(i):
				message = "Can't reach %s from this gather." % LANES[i].to_lower()
			elif i != guard:
				_point(true, "Open %s lane. Your return scores." % LANES[i].to_lower())
				return
			elif contacts >= 2:
				_point(false, "Third return into the guard. Your side tires first.")
				return
			else:
				contacts += 1
				var previous := guard
				incoming = (previous + contacts) % 3
				driven = contacts == 1
				guard = (previous + 1) % 3
				gather_lane = -1
				phase = Phase.RECEIVE
				message = "Blocked. Read the new landing lane."
				_note("Guard blocks; counter is %s to %s." % [_ball_kind().to_lower(), LANES[incoming].to_lower()])
		Phase.POINT:
			if i != 0: return
			rally += 1
			_serve()
			return
		Phase.MATCH:
			return
	_refresh()

func _reachable(i: int) -> bool:
	return gather_lane < 0 or i == gather_lane or i == 1

func _point(home: bool, reason: String) -> void:
	if home: points.x += 1
	else: points.y += 1
	message = reason
	_note(reason)
	phase = Phase.MATCH if maxi(points.x, points.y) >= GOAL else Phase.POINT
	_refresh()

func _refresh() -> void:
	score.text = "YOU  %d     :     %d  RIVALS" % [points.x, points.y]
	for button in decisions:
		button.hide()
		button.disabled = false
	status.text = message
	match phase:
		Phase.RECEIVE:
			header.text = "01  /  RECEIVE"
			detail.text = "%s ball to %s." % [_ball_kind(), LANES[incoming].to_lower()]
			context.text = "Spread covers all lanes but loses to a driven ball. Gather saves either ball, but limits return angles."
			_option(0, "Spread formation   [S]")
			_option(1, "Gather at %s   [G]" % LANES[incoming].to_lower())
		Phase.RETURN:
			header.text = "02  /  RETURN"
			detail.text = "Rivals guard %s. Find an open lane." % LANES[guard].to_lower()
			context.text = "Closed angles are marked. A guarded return comes back at you; a third blocked return loses the point."
			for i in range(3):
				_option(i, "%s   [%d]  ·  %s" % [LANES[i].capitalize(), i + 1,
					("guarded" if i == guard else "open") if _reachable(i) else "out of reach"], not _reachable(i))
		Phase.POINT:
			header.text = "POINT OVER"
			detail.text = "First team to five wins."
			context.text = "The next serve begins when you are ready."
			_option(0, "Next rally   [Space]")
		Phase.MATCH:
			header.text = "MATCH WON" if points.x >= GOAL else "MATCH LOST"
			detail.text = "Final score   %d : %d" % [points.x, points.y]
			context.text = "Restart to replay the opening serve."
	var recent: Array[String] = []
	for i in range(maxi(history.size() - 4, 0), history.size()):
		recent.append(history[i])
	log_view.text = "\n".join(recent)
	queue_redraw()

func _option(i: int, name_text: String, disabled := false) -> void:
	decisions[i].text = name_text
	decisions[i].disabled = disabled
	decisions[i].show()

func _lane_x(i: int) -> float:
	return COURT.position.x + (i + 0.5) * COURT.size.x / 3.0

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1200, 740), BACK)
	draw_rect(Rect2(771, 118, 397, 590), SKY)
	draw_line(Vector2(43, 107), Vector2(1150, 107), Color("#52657b"))
	draw_rect(COURT, Color("#ad6549"))
	var lane_w := COURT.size.x / 3.0
	for i in range(3):
		var x := COURT.position.x + i * lane_w
		var away := Rect2(x, COURT.position.y, lane_w, NET_Y - COURT.position.y)
		var home := Rect2(x, NET_Y, lane_w, COURT.end.y - NET_Y)
		if i == guard and phase == Phase.RETURN:
			draw_rect(away.grow(-2), Color("#874354"))
		elif phase == Phase.RETURN and not _reachable(i):
			draw_rect(away.grow(-2), Color("#70544d"))
		if i == incoming and phase == Phase.RECEIVE:
			draw_rect(home.grow(-2), Color("#c5844e"))
		if i > 0:
			draw_line(Vector2(x, COURT.position.y), Vector2(x, COURT.end.y), CREAM.darkened(0.23))
		_court_text(Vector2(x + 12, 184), LANES[i], 14, CREAM)
		_court_text(Vector2(x + 12, 518), LANES[i], 14, CREAM)
	draw_line(Vector2(41, NET_Y), Vector2(745, NET_Y), BACK, 11)
	draw_dashed_line(Vector2(43, NET_Y), Vector2(743, NET_Y), CREAM, 3, 10)
	draw_rect(COURT, CREAM, false, 2)
	for i in range(3):
		_draw_player(Vector2(_lane_x(i), RIVAL_Y), CORAL)
		var x := _lane_x(i) if gather_lane < 0 else _lane_x(gather_lane) + (i - 1) * 36.0
		_draw_player(Vector2(x, HOME_Y), TEAL)
	if phase == Phase.RECEIVE:
		var from := Vector2(_lane_x(guard), RIVAL_Y + 24.0)
		var target := Vector2(_lane_x(incoming), HOME_Y - 29.0)
		draw_dashed_line(from, target, GOLD, 3.0, 7.0, true)
		draw_arc(target, 15, 0, TAU, 36, GOLD, 3.0, true)
		draw_circle(from.lerp(target, 0.53), 9, GOLD, true, -1, true)
	elif phase == Phase.RETURN:
		for i in range(3):
			if not _reachable(i):
				var text := "GUARD / NO ANGLE" if i == guard else "NO ANGLE"
				_court_text(Vector2(_lane_x(i) - 54.0, RIVAL_Y + 44), text, 12, CREAM)
			elif i == guard:
				_court_text(Vector2(_lane_x(i) - 36.0, RIVAL_Y + 44), "GUARDED", 12, CREAM)
		draw_circle(Vector2(_lane_x(incoming), HOME_Y - 29.0), 9, GOLD, true, -1, true)
	draw_line(Vector2(43, 611), Vector2(743, 611), Color("#52657b"))

func _draw_player(pos: Vector2, jersey: Color) -> void:
	draw_circle(pos, 14, BACK, true, -1, true)
	draw_circle(pos, 10, jersey, true, -1, true)
	draw_line(pos + Vector2(-5, 1), pos + Vector2(5, 1), BACK, 2.0)

func _court_text(pos: Vector2, value: String, size_px: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
