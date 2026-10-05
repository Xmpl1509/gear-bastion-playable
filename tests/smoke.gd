extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(not game.cannon_on(0))
	var layout = [Vector2(270, 654), Vector2(270, 594), Vector2(210, 594), Vector2(150, 594), Vector2(330, 594), Vector2(390, 594)]
	for i in range(layout.size()):
		game.press(game.gears[i].pos)
		game.gears[i].pos = layout[i]
		game.release()
	assert(game.cannon_on(0) and game.cannon_on(1), "Both cannons must receive motor power")
	game.press(Vector2(270, 910))
	assert(game.phase == "battle")
	seed(42)
	for i in range(6000):
		game._process(1.0 / 60.0)
		if game.phase == "win":
			break
	assert(game.phase == "win", "Connected layout must win")
	assert(game.kills == 30)
	var opened: Array[String] = []
	game.link_opener = func(url: String) -> void: opened.append(url)
	game.press(Vector2(270, 596))
	assert(opened == [game.CTA_URL], "End card CTA must open the exact campaign URL")
	assert(game.phase == "win", "CTA must not reset the game")
	game.press(Vector2(270, 660))
	assert(game.phase == "build", "Replay must restart the playable")
	game.press(Vector2(400, 47))
	assert(opened.size() == 2, "Header CTA must also open the destination")
	game.reset()
	game.phase = "battle"
	for i in range(6000):
		game._process(1.0 / 60.0)
		if game.phase == "lose":
			break
	assert(game.phase == "lose", "Unpowered layout must lose")
	game.press(Vector2(270, 596))
	assert(opened.size() == 3, "Loss end card must allow click-through")
	game.reset()
	assert(game.health == 100 and game.enemies.is_empty())
	print("PASS: drag/drop, power network, victory, defeat, replay, CTA destination and hit areas")
	quit()
