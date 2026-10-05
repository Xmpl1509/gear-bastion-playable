extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.add_child(load("res://main.tscn").instantiate())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview.png")
	quit()
