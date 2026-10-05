extends Node2D

const INK = Color("152d43")
const GOLD = Color("ffcd56")
const MINT = Color("65e6bb")
const BOARD = Rect2(36, 490, 468, 272)
const ROOT = Vector2(270, 714)
const TARGETS = [Vector2(150, 534), Vector2(390, 534)]
const CTA_URL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
const END_CTA = Rect2(90, 564, 360, 64)
const REPLAY = Rect2(90, 638, 360, 44)
const HEADER_CTA = Rect2(320, 30, 180, 34)
var link_opener: Callable = OS.shell_open
var font: Font = ThemeDB.fallback_font
var gears: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var powered: Array[int] = []
var dragging = -1
var pointer = Vector2.ZERO
var origin = Vector2.ZERO
var time = 0.0
var elapsed = 0.0
var spawn_clock = 0.0
var fire_clock = 0.0
var health = 100.0
var kills = 0
var spawned = 0
var phase = "build"
var message = "KÉO BÁNH RĂNG ĐỂ NỐI HAI PHÁO"
var mute = false

func _ready() -> void:
	reset()

func reset() -> void:
	gears.clear()
	for i in range(7):
		gears.append({"pos": Vector2(90 + i * 60, 834), "home": Vector2(90 + i * 60, 834), "placed": false})
	enemies.clear()
	shots.clear()
	sparks.clear()
	health = 100
	kills = 0
	spawned = 0
	elapsed = 0
	spawn_clock = 0
	fire_clock = 0
	dragging = -1
	phase = "build"
	message = "KÉO BÁNH RĂNG ĐỂ NỐI HAI PHÁO"
	reconnect()

func reconnect() -> void:
	powered.clear()
	var changed = true
	while changed:
		changed = false
		for i in range(gears.size()):
			if i == dragging or not gears[i].placed or i in powered:
				continue
			var connected: bool = gears[i].pos.distance_to(ROOT) < 72
			for j in powered:
				if gears[i].pos.distance_to(gears[j].pos) < 72:
					connected = true
			if connected:
				powered.append(i)
				changed = true

func cannon_on(index: int) -> bool:
	for i in powered:
		if gears[i].pos.distance_to(TARGETS[index]) < 72:
			return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer = get_global_mouse_position()
		if event.pressed:
			press(pointer)
		else:
			release()
	elif event is InputEventMouseMotion:
		pointer = get_global_mouse_position()
		if dragging >= 0:
			gears[dragging].pos = pointer
	elif event is InputEventScreenTouch:
		pointer = event.position
		if event.pressed:
			press(pointer)
		else:
			release()
	elif event is InputEventScreenDrag:
		pointer = event.position
		if dragging >= 0:
			gears[dragging].pos = pointer

func press(p: Vector2) -> void:
	if phase in ["win", "lose"]:
		if END_CTA.has_point(p):
			open_destination()
		elif REPLAY.has_point(p):
			reset()
		return
	if HEADER_CTA.has_point(p):
		open_destination()
		return
	if Rect2(36, 884, 468, 54).has_point(p):
		if phase == "build":
			if not cannon_on(0) and not cannon_on(1):
				message = "NỐI BÁNH RĂNG VÀO PHÁO TRƯỚC!"
			else:
				phase = "battle"
				message = "GIỮ THÀNH! CÓ THỂ ĐỔI BÁNH RĂNG"
		return
	for i in range(gears.size() - 1, -1, -1):
		if p.distance_to(gears[i].pos) < 40:
			dragging = i
			origin = gears[i].pos
			gears[i].pos = p
			reconnect()
			break

func open_destination() -> void:
	# Keep this synchronous inside the tap so Web browsers allow the new tab.
	link_opener.call(CTA_URL)

func release() -> void:
	if dragging < 0:
		return
	var p: Vector2 = gears[dragging].pos
	var snap = Vector2(90 + round((p.x - 90) / 60) * 60, 534 + round((p.y - 534) / 60) * 60)
	var valid = BOARD.has_point(p) and snap.y <= 714 and snap.x >= 90 and snap.x <= 450
	if snap.distance_to(ROOT) < 10 or snap in TARGETS:
		valid = false
	for i in range(gears.size()):
		if i != dragging and gears[i].placed and snap.distance_to(gears[i].pos) < 40:
			valid = false
	if valid:
		gears[dragging].pos = snap
		gears[dragging].placed = true
	else:
		gears[dragging].pos = gears[dragging].home
		gears[dragging].placed = false
	dragging = -1
	reconnect()
	if cannon_on(0) and cannon_on(1):
		message = "HAI PHÁO ĐÃ SẴN SÀNG • BẮT ĐẦU!"
	elif not powered.is_empty():
		message = "NỐI TIẾP ĐẾN BÁNH RĂNG CỦA PHÁO"

func _process(delta: float) -> void:
	time += delta
	if phase == "battle":
		elapsed += delta
		spawn_clock -= delta
		if spawn_clock <= 0 and spawned < 30:
			var boss = spawned == 29
			enemies.append({"pos": Vector2(randf_range(70, 470), 178), "hp": 160.0 if boss else 28.0 + floor(spawned / 10.0) * 12, "max": 160.0 if boss else 28.0 + floor(spawned / 10.0) * 12, "speed": 20.0 if boss else randf_range(24, 36), "boss": boss})
			spawned += 1
			spawn_clock = 0.95
		fire_clock -= delta
		if fire_clock <= 0:
			fire_clock = 0.28
			for c in range(2):
				if cannon_on(c) and not enemies.is_empty():
					var target = 0
					for j in range(enemies.size()):
						if enemies[j].pos.y > enemies[target].pos.y:
							target = j
					shots.append({"from": Vector2(TARGETS[c].x, 444), "to": enemies[target].pos, "life": 0.14})
					enemies[target].hp -= 12
		for i in range(enemies.size() - 1, -1, -1):
			var e = enemies[i]
			e.pos.y += e.speed * delta
			if e.hp <= 0:
				for j in range(9):
					sparks.append({"pos": e.pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(30, 130), "life": 0.5})
				enemies.remove_at(i)
				kills += 1
			elif e.pos.y >= 431:
				health -= 24 if e.boss else 9
				enemies.remove_at(i)
		if health <= 0:
			phase = "lose"
		elif spawned == 30 and enemies.is_empty():
			phase = "win"
	for i in range(shots.size() - 1, -1, -1):
		shots[i].life -= delta
		if shots[i].life <= 0:
			shots.remove_at(i)
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i].life -= delta
		sparks[i].pos += sparks[i].vel * delta
		if sparks[i].life <= 0:
			sparks.remove_at(i)
	queue_redraw()

func panel(rect: Rect2, color: Color, radius: int = 16) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func label_text(s: String, p: Vector2, size: int, color: Color = Color.WHITE) -> void:
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(s: String, y: float, size: int, color: Color = Color.WHITE) -> void:
	label_text(s, Vector2((540 - font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x) / 2, y), size, color)

func gear(p: Vector2, color: Color, angle: float, active: bool, radius: float = 30) -> void:
	if active:
		draw_circle(p, radius + 8, Color(0.4, 0.9, 0.75, 0.12))
	var points = PackedVector2Array()
	for i in range(48):
		var r = radius if i % 4 in [1, 2] else radius - 6
		points.append(p + Vector2.from_angle(angle + i * TAU / 48) * r)
	draw_colored_polygon(points, INK)
	var inner = PackedVector2Array()
	for v in points:
		inner.append(p + (v - p) * 0.90)
	draw_colored_polygon(inner, color)
	draw_circle(p, radius * 0.61, color.darkened(0.2))
	draw_arc(p, radius * 0.60, 0, TAU, 32, color.lightened(0.25), 2)
	for i in range(3):
		var a = angle + i * TAU / 3
		draw_line(p + Vector2.from_angle(a) * 9, p + Vector2.from_angle(a) * 19, INK, 5)
	draw_circle(p, 7, INK)
	draw_circle(p, 3, Color("ddeaf0"))

func _draw() -> void:
	draw_rect(Rect2(0, 0, 540, 960), Color("0b1b2a"))
	panel(Rect2(20, 22, 500, 89), INK)
	label_text("GEAR", Vector2(40, 57), 28, GOLD)
	label_text("BASTION", Vector2(40, 89), 28)
	panel(HEADER_CTA, GOLD, 9)
	label_text("CHƠI NGAY  ↗", Vector2(341, 53), 17, INK)
	label_text("%02d / 30" % kills, Vector2(359, 85), 25)
	panel(Rect2(36, 126, 468, 37), Color("243d50"), 10)
	panel(Rect2(40, 130, 460 * maxf(health, 0) / 100, 29), MINT if health > 30 else Color("ff7471"), 8)
	centered("THÀNH • %d%%" % maxi(0, int(health)), 151, 17, INK)
	panel(Rect2(36, 176, 468, 293), Color("446b63"))
	for x in range(50, 500, 45):
		for y in range(190, 440, 44):
			draw_line(Vector2(x, y), Vector2(x + 5, y - 7), Color("527a6d"), 2)
	draw_rect(Rect2(247, 176, 46, 260), Color(0.7, 0.75, 0.6, 0.08))
	centered("ĐỢT %d / 3" % mini(3, 1 + spawned / 10), 201, 16, Color("c3dbc4"))
	if phase == "build":
		centered("QUÁI VẬT ĐANG ĐẾN…", 288, 23, Color("e4eed0"))
		centered("Lắp bộ truyền động để bảo vệ thành", 317, 17, Color("c3dbc4"))
	for e in enemies:
		var p: Vector2 = e.pos
		var r = 23.0 if e.boss else 14.0
		draw_ellipse_shadow(p, r)
		draw_line(p + Vector2(-7, 6), p + Vector2(-9, 19 + sin(time * 10) * 3), INK, 6)
		draw_line(p + Vector2(7, 6), p + Vector2(9, 19 - sin(time * 10) * 3), INK, 6)
		draw_circle(p, r + 2, INK)
		draw_circle(p, r, Color("ba78ce") if e.boss else Color("ed8570"))
		draw_circle(p + Vector2(-5, -2), 3, Color.WHITE)
		draw_circle(p + Vector2(5, -2), 3, Color.WHITE)
		draw_line(p + Vector2(-5, 7), p + Vector2(5, 7), INK, 3)
		draw_rect(Rect2(p.x - r, p.y - r - 9, r * 2, 4), INK)
		draw_rect(Rect2(p.x - r, p.y - r - 9, r * 2 * maxf(e.hp, 0) / e.max, 4), GOLD)
	for s in shots:
		draw_line(s.from, s.to, Color("fff2be"), 3)
		draw_circle(s.to, 7, GOLD)
	for s in sparks:
		draw_circle(s.pos, 3 * s.life / 0.5, GOLD)
	panel(Rect2(30, 427, 480, 43), Color("879cad"), 5)
	for x in range(40, 500, 32):
		draw_rect(Rect2(x, 418, 22, 18), Color("a7bdc9"))
	for c in range(2):
		var p = Vector2(TARGETS[c].x, 444)
		draw_circle(p, 27, INK)
		draw_circle(p, 22, MINT if cannon_on(c) else Color("718391"))
		panel(Rect2(p.x - 10, p.y - 43, 20, 39), GOLD if cannon_on(c) else Color("a6b3b8"), 5)
	panel(BOARD, Color("21394e"))
	for x in range(90, 451, 60):
		for y in range(534, 715, 60):
			draw_circle(Vector2(x, y), 3, Color("3e586c"))
	for c in range(2):
		draw_line(TARGETS[c], Vector2(TARGETS[c].x, 470), MINT if cannon_on(c) else Color("526a7c"), 8)
		gear(TARGETS[c], MINT if cannon_on(c) else Color("718391"), -time * 2 if cannon_on(c) else 0, cannon_on(c))
	gear(ROOT, GOLD, time * 2, true, 33)
	label_text("MOTOR", Vector2(244, 753), 12, GOLD)
	if phase == "build" and powered.is_empty() and dragging < 0:
		for p in [Vector2(270, 654), Vector2(270, 594), Vector2(210, 594), Vector2(150, 594), Vector2(330, 594), Vector2(390, 594)]:
			draw_arc(p, 27, 0, TAU, 32, Color(0.4, 0.9, 0.75, 0.35 + sin(time * 4) * 0.1), 2)
		centered("Kéo vào vòng sáng • Nối từ MOTOR", 791, 17, MINT)
	else:
		centered("%d/2 PHÁO HOẠT ĐỘNG" % (int(cannon_on(0)) + int(cannon_on(1))), 791, 17, MINT)
	panel(Rect2(36, 800, 468, 68), Color("172e42"))
	for i in range(gears.size()):
		if i != dragging:
			gear(gears[i].pos, MINT if i in powered else GOLD, time * 2 * (-1 if i % 2 else 1) if i in powered else 0, i in powered)
	if dragging >= 0:
		gear(gears[dragging].pos, GOLD, time * 2, true)
	panel(Rect2(36, 884, 468, 54), GOLD if phase == "build" else Color("29465b"), 14)
	centered("BẮT ĐẦU PHÒNG THỦ  ▶" if phase == "build" else message, 918, 19 if phase == "build" else 15, INK if phase == "build" else MINT)
	if phase == "build":
		centered(message, 483, 14, GOLD)
	if phase in ["win", "lose"]:
		draw_rect(Rect2(0, 0, 540, 960), Color(0.02, 0.06, 0.1, 0.86))
		panel(Rect2(52, 296, 436, 422), INK, 28)
		gear(Vector2(270, 365), GOLD, time * 0.5, true, 44)
		centered("THÀNH ĐÃ ĐƯỢC CỨU!" if phase == "win" else "THỬ MỘT CÁCH NỐI KHÁC!", 452, 26, GOLD)
		centered("%d quái bị hạ • %d%% máu thành" % [kills, maxi(0, int(health))], 494, 19)
		centered("SẴN SÀNG CHO THỬ THÁCH TIẾP THEO?", 537, 17, MINT)
		panel(Rect2(END_CTA.position - Vector2.ONE * 4, END_CTA.size + Vector2.ONE * 8), Color(1, 0.8, 0.34, 0.15 + 0.08 * sin(time * 4)))
		panel(END_CTA, GOLD)
		centered("CHƠI NGAY  ↗", 605, 26, INK)
		panel(REPLAY, Color("29465b"), 12)
		centered("CHƠI LẠI  ↻", 668, 18)
		centered("CHƠI NGAY sẽ mở YouTube", 703, 12, Color("9fb6c8"))

func draw_ellipse_shadow(p: Vector2, r: float) -> void:
	draw_set_transform(p + Vector2(0, 20), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, r + 5, Color(0, 0, 0, 0.20))
	draw_set_transform(Vector2.ZERO)
