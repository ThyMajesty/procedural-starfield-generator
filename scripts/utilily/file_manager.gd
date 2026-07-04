class_name FileManager
extends RefCounted

var save_dialog: FileDialog
var _pending_image: Image
var _pending_seed: int
var _pending_settings: Dictionary

func _init(parent: Node) -> void:
	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.png", "PNG Image")
	save_dialog.file_selected.connect(_on_file_selected)
	parent.add_child(save_dialog)

func request_save(image: Image, seed_value: int, settings: Dictionary) -> void:
	if not image:
		push_warning("Nothing generated yet.")
		return
	_pending_image = image
	_pending_seed = seed_value
	_pending_settings = settings

	save_dialog.current_file = "starfield_%d_%d.png" % [_pending_seed, Time.get_unix_time_from_system()]
	save_dialog.popup_centered_ratio()

func _on_file_selected(path: String) -> void:
	var err := _pending_image.save_png(path)
	if err != OK:
		push_error("Failed to save PNG: %s" % err)
	else:
		print("Saved: %s" % path)