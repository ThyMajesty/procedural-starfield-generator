class_name FileManager
extends RefCounted

var save_dialog: FileDialog
var _pending_image: Image
var _pending_seed: int
var _pending_settings: PSG_Settings

# need CRC32 to write png metadata
static var CRC32_TABLE = _get_crc32_table()

static func _get_crc32_table() -> Array:
	const P  = 0xEDB88320
	var crc_table: Array[int]
	crc_table.resize(256)
	for n in 256:
		var crc = n
		for i in 8:
			if crc & 1:
				crc = ((crc >> 1) ^ P) & 0xFFFFFFFF
			else:
				crc = (crc >> 1) & 0xFFFFFFFF
		crc_table[n] = crc
	return crc_table

func crc32(data) -> int:
	var crc = 0xFFFFFFFF
	var xor_out = 0xFFFFFFFF

	var bytes: PackedByteArray = data.to_utf8_buffer()

	for byte in bytes:
		crc = (CRC32_TABLE[(crc ^ byte) & 0xFF] ^ (crc >> 8)) & 0xFFFFFFFF

	return crc ^ xor_out

func _init(parent: Node) -> void:
	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.png", "PNG Image")
	save_dialog.file_selected.connect(_on_file_selected)
	parent.add_child(save_dialog)

func request_save(image: Image, seed_value: int, settings: PSG_Settings) -> void:
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
