extends VBoxContainer

#  ¯\_(ツ)_/¯

signal setting_changed(value: Variant, key: String)

# settings
var resolution: int = 4096
var star_count: int = 64000
var seed_value: int = 666
var use_random_seed: bool = false;

var use_density_noise: bool = true
var density_noise_scale: float = 2.0
var density_bias: float = 1.0

var brightness_power: float = 16.0
var min_brightness: float = 0.1
var max_brightness: float = 1.0

var min_radius: float = 0.5
var max_radius: float = 2.2
var size_follows_brightness: bool = true

var giant_chance: float = 0.001
var giant_size_multiplier: float = 5.0

var use_color_variation: bool = true
var warm_chance: float = 0.33
var blue_chance: float = 0.25

var background_color: Color = Color(0.0, 0.0, 0.02, 1.0)

# nebula
var use_nebula: bool = true
var nebula_scale: float = 2.0
var nebula_octaves: int = 8
var nebula_intensity: float = 0.4
var nebula_color_count: int = 5


var nebula_color_1: Color = Color(0.4, 0.15, 0.5, 1.0)
var nebula_color_2: Color = Color(0.15, 0.3, 0.6, 1.0)
var nebula_color_3: Color = Color(0.8, 0.3, 0.4, 1.0)
var nebula_color_4: Color = Color(0.9, 0.6, 0.2, 1.0)
var nebula_color_5: Color = Color(0.2, 0.5, 0.5, 1.0)

var nebula_warp_strength: float = 72.0
var nebula_warp_scale: float = 10.0

var nebula_dist_scale: float = 0.5
var nebula_dist_octaves: int = 3
var nebula_dist_strength: float = 0.6

var nebula_curl_scale: float = 3.0
var nebula_curl_strength: float = 150.0
var nebula_curl_octaves: int = 3
var nebula_curl_eps: float = 1.0

func _collect_nebula_colors() -> Array[Color]:
	var all: Array[Color] = [nebula_color_1, nebula_color_2, nebula_color_3, nebula_color_4, nebula_color_5]
	return all.slice(0, nebula_color_count)

# TODO: move GUI and potentially settings to a separate class(s)
# ui typed config driving both widget generation and value application
# type: "bool" | "color" | "int" | "float"
var widget_config: Array[Dictionary] = [
	{ key = "resolution", type = "int", min_value = 256, max_value = 16384, step = 256 },
	{ key = "star_count", type = "int", min_value = 100, max_value = 1000000, step = 1 },
	{ key = "seed_value", type = "int", min_value = 0, max_value = 1000000, step = 1 },
	{ key = "use_random_seed", type = "bool"},

	{ key = "use_density_noise", type = "bool" },
	{ key = "density_noise_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1 },
	{ key = "density_bias", type = "float", min_value = 0.1, max_value = 5.0, step = 0.1 },

	{ key = "brightness_power", type = "float", min_value = 0.5, max_value = 32.0, step = 0.1 },
	{ key = "min_brightness", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01 },
	{ key = "max_brightness", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01 },

	{ key = "min_radius", type = "float", min_value = 0.1, max_value = 10.0, step = 0.1 },
	{ key = "max_radius", type = "float", min_value = 0.1, max_value = 10.0, step = 0.1 },
	{ key = "size_follows_brightness", type = "bool" },

	{ key = "giant_chance", type = "float", min_value = 0.0, max_value = 0.1, step = 0.001 },
	{ key = "giant_size_multiplier", type = "float", min_value = 1.0, max_value = 10.0, step = 0.1 },

	{ key = "use_color_variation", type = "bool" },
	{ key = "warm_chance", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01 },
	{ key = "blue_chance", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01 },

	{ key = "background_color", type = "color" },

	{ key = "use_nebula", type = "bool" },
	{ key = "nebula_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1 },
	{ key = "nebula_octaves", type = "int", min_value = 1, max_value = 16, step = 1 },
	{ key = "nebula_intensity", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01 },
	{ key = "nebula_color_count", type = "int", min_value = 1, max_value = 5, step = 1 },

	{ key = "nebula_color_1", type = "color" },
	{ key = "nebula_color_2", type = "color" },
	{ key = "nebula_color_3", type = "color" },
	{ key = "nebula_color_4", type = "color" },
	{ key = "nebula_color_5", type = "color" },

	{ key = "nebula_warp_strength", type = "float", min_value = 0.0, max_value = 2000.0, step = 1.0 },
	{ key = "nebula_warp_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1 },

	{ key = "nebula_dist_scale", type = "float", min_value = 0.05, max_value = 10.0, step = 0.05 },
	{ key = "nebula_dist_octaves", type = "int", min_value = 1, max_value = 8, step = 1 },
	{ key = "nebula_dist_strength", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01 },

	{ key = "nebula_curl_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1 },
	{ key = "nebula_curl_strength", type = "float", min_value = 0.0, max_value = 100000.0, step = 5.0 },
	{ key = "nebula_curl_octaves", type = "int", min_value = 1, max_value = 8, step = 1 },
	{ key = "nebula_curl_eps", type = "float", min_value = 0.1, max_value = 10.0, step = 0.1 },
]

var time_last_elapsed := Time.get_ticks_msec() 

# TODO revisit nodes resolution; consider just find with caching instead of explicit
@onready var settings_panel: VBoxContainer = get_node("SettingsPanel")
@onready var sprite_2d: Sprite2D = get_node("../../../SubViewportContainer/SubViewport/Node2D/Sprite2D")
@onready var generate_button: Button = get_node("../../HBoxContainer/GenerateButton")
@onready var save_button: Button = get_node("../../HBoxContainer/SaveButton")
@onready var info_label: Label = get_node("../../HBoxContainer/InfoLabel")

var widget_dict: Dictionary = {}
var _image: Image
var _texture: ImageTexture

var save_dialog: FileDialog

func _ready() -> void:
	_build_widgets()

	for uiw_node in get_tree().get_nodes_in_group("UIWidget"):
		if uiw_node is UIWidget:
			var key = uiw_node.property_name
			widget_dict[key] = uiw_node
			widget_dict[key].value_changed.connect(_value_changed.bind(key))
			widget_dict[key]._set_value(self[key])

	generate_button.pressed.connect(generate)

	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.png", "PNG Image")
	save_dialog.current_file = "starfield_%d.png" % Time.get_unix_time_from_system()
	save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(save_dialog)

	save_button.pressed.connect(_on_save_pressed)

func _build_widgets() -> void:
	for cfg in widget_config:
		var node: UIWidget
		match cfg.type:
			"bool":
				node = UIBoolWidget.new()
			"color":
				node = UIColorPickerWidget.new()
			"float":
				node = UIFloatWidget.new()
			"int":
				node = UIIntWidget.new()
			_:
				push_error("Unknown widget type: %s" % cfg.type)
				continue

		node.name = cfg.key
		if cfg.has("view"):
			node.view_name = cfg.view

		if cfg.type in ["float", "int"]:
			if cfg.has("min_value"): node.min_value = cfg.min_value
			if cfg.has("max_value"): node.max_value = cfg.max_value
			if cfg.has("step"): node.step = cfg.step

		settings_panel.add_child(node)

# Consider adding a bool setting and triggerring generation on value change if compute cap enables 
func _value_changed(value: Variant, key: String, emit: bool = true) -> void:
	if self[key] == value:
		return
	self[key] = value
	if emit:
		setting_changed.emit(value, key)

func _build_info_label() -> void:
	info_label.text = "Elapsed: " + str(time_last_elapsed) + "ms"

func _on_save_pressed() -> void:
	if not _image:
		push_warning("Nothing generated yet.")
		return
	save_dialog.popup_centered_ratio(0.6)

func _on_save_file_selected(path: String) -> void:
	var err := _image.save_png(path)
	if err != OK:
		push_error("Failed to save PNG: %s" % err)
	else:
		print("Saved: %s" % path)

#TODO: move GPU stuff to a separate class

func generate() -> void:
	var time_start = Time.get_ticks_msec()
	if use_random_seed:
		seed_value = randi()

	_image = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	var data := _bake_gpu()

	_image.set_data(resolution, resolution, false, Image.FORMAT_RGBA8, data)
	_texture = ImageTexture.create_from_image(_image)

	sprite_2d.texture = _texture
	var time_end = Time.get_ticks_msec()
	time_last_elapsed = time_end - time_start

	_build_info_label()


func _build_push_constant_star_gen(attempt_count: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	buf.put_32(attempt_count)
	buf.put_32(star_count)       # max_stars (buffer capacity)
	buf.put_32(resolution)
	buf.put_32(seed_value)

	buf.put_float(density_noise_scale)
	buf.put_float(density_bias)
	buf.put_32(1 if use_density_noise else 0)
	buf.put_float(brightness_power)

	buf.put_float(min_brightness)
	buf.put_float(max_brightness)
	buf.put_float(min_radius)
	buf.put_float(max_radius)

	buf.put_32(1 if size_follows_brightness else 0)
	buf.put_32(1 if use_color_variation else 0)
	buf.put_float(warm_chance)
	buf.put_float(blue_chance)

	buf.put_float(giant_chance)
	buf.put_float(giant_size_multiplier)
	buf.put_float(0.0)
	buf.put_float(0.0)

	return buf.data_array

func _build_nebula_color_buffer() -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	for c in _collect_nebula_colors():
		buf.put_float(c.r)
		buf.put_float(c.g)
		buf.put_float(c.b)
		buf.put_float(c.a)

	return buf.data_array

func _build_push_constant_nebula(color_count: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	buf.put_float(nebula_scale)
	buf.put_32(nebula_octaves)
	buf.put_float(nebula_intensity)
	buf.put_32(seed_value)

	buf.put_32(color_count)
	buf.put_float(float(resolution))
	buf.put_float(nebula_warp_strength)
	buf.put_float(nebula_warp_scale)

	buf.put_float(background_color.r)
	buf.put_float(background_color.g)
	buf.put_float(background_color.b)
	buf.put_float(background_color.a)

	buf.put_32(1 if use_nebula else 0)
	buf.put_float(nebula_dist_scale)
	buf.put_32(nebula_dist_octaves)
	buf.put_float(nebula_dist_strength)

	buf.put_float(nebula_curl_scale)
	buf.put_float(nebula_curl_strength)
	buf.put_32(nebula_curl_octaves)
	buf.put_float(nebula_curl_eps)

	return buf.data_array

func _build_push_constant_stars(star_count_actual: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	buf.put_32(star_count_actual)
	buf.put_32(resolution)
	buf.put_float(0.0)
	buf.put_float(0.0)

	return buf.data_array

func _bake_gpu() -> PackedByteArray:
	var rd := RenderingServer.create_local_rendering_device()

	# shared output image
	var fmt := RDTextureFormat.new()
	fmt.width = resolution
	fmt.height = resolution
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view := RDTextureView.new()
	var tex := rd.texture_create(fmt, view, [])

	# nebula pass: either bg_color or nebula depending on use_nebula
	var neb_shader := rd.shader_create_from_spirv(load("res://shaders/compute/nebula.glsl").get_spirv())

	var color_bytes := _build_nebula_color_buffer()
	var color_buf := rd.storage_buffer_create(color_bytes.size(), color_bytes)

	var neb_img_uniform := RDUniform.new()
	neb_img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	neb_img_uniform.binding = 0
	neb_img_uniform.add_id(tex)

	var neb_color_uniform := RDUniform.new()
	neb_color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	neb_color_uniform.binding = 1
	neb_color_uniform.add_id(color_buf)

	var neb_set := rd.uniform_set_create([neb_img_uniform, neb_color_uniform], neb_shader, 0)
	var neb_pipeline := rd.compute_pipeline_create(neb_shader)
	var color_count := nebula_color_count
	var neb_push := _build_push_constant_nebula(color_count)

	# star generation pass
	var attempt_count := star_count * 20
	var gen_shader := rd.shader_create_from_spirv(load("res://shaders/compute/stars_generate.glsl").get_spirv())

	var counter_bytes := PackedByteArray()
	counter_bytes.resize(4)
	var counter_buf := rd.storage_buffer_create(4, counter_bytes)

	var star_buf := rd.storage_buffer_create(star_count * 32)

	var counter_uniform := RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = 0
	counter_uniform.add_id(counter_buf)

	var star_gen_buf_uniform := RDUniform.new()
	star_gen_buf_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	star_gen_buf_uniform.binding = 1
	star_gen_buf_uniform.add_id(star_buf)

	var gen_set := rd.uniform_set_create([counter_uniform, star_gen_buf_uniform], gen_shader, 0)
	var gen_pipeline := rd.compute_pipeline_create(gen_shader)
	var gen_push := _build_push_constant_star_gen(attempt_count)

	# submission 1: nebula + star generation
	var cl := rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(cl, neb_pipeline)
	rd.compute_list_bind_uniform_set(cl, neb_set, 0)
	rd.compute_list_set_push_constant(cl, neb_push, neb_push.size())
	rd.compute_list_dispatch(cl, ceili(resolution / 8.0), ceili(resolution / 8.0), 1)

	rd.compute_list_bind_compute_pipeline(cl, gen_pipeline)
	rd.compute_list_bind_uniform_set(cl, gen_set, 0)
	rd.compute_list_set_push_constant(cl, gen_push, gen_push.size())
	rd.compute_list_dispatch(cl, ceili(attempt_count / 64.0), 1, 1)

	rd.compute_list_end()
	rd.submit()
	rd.sync()

	var count_data := rd.buffer_get_data(counter_buf)
	var star_count_actual: int = mini(count_data.decode_u32(0), star_count)

	# star blit pass (own uniform set, needs image + star buffer)
	var stars_shader := rd.shader_create_from_spirv(load("res://shaders/compute/stars.glsl").get_spirv())

	var stars_img_uniform := RDUniform.new()
	stars_img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	stars_img_uniform.binding = 0
	stars_img_uniform.add_id(tex)

	var stars_buf_uniform := RDUniform.new()
	stars_buf_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	stars_buf_uniform.binding = 1
	stars_buf_uniform.add_id(star_buf)

	var stars_set := rd.uniform_set_create([stars_img_uniform, stars_buf_uniform], stars_shader, 0)
	var stars_pipeline := rd.compute_pipeline_create(stars_shader)
	var stars_push := _build_push_constant_stars(star_count_actual)

	if star_count_actual > 0:
		var cl2 := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(cl2, stars_pipeline)
		rd.compute_list_bind_uniform_set(cl2, stars_set, 0)
		rd.compute_list_set_push_constant(cl2, stars_push, stars_push.size())
		rd.compute_list_dispatch(cl2, ceili(star_count_actual / 64.0), 1, 1)
		rd.compute_list_end()
		rd.submit()
		rd.sync()

	var data := rd.texture_get_data(tex, 0)

	# order matters, but maybe don't need to free rids manually duno..
	for rid in [
		stars_set, gen_set, neb_set,
		stars_pipeline, gen_pipeline, neb_pipeline,
		stars_shader, gen_shader, neb_shader,
		color_buf, star_buf, counter_buf, tex
	]:
		rd.free_rid(rid)
	rd.free()

	return data
