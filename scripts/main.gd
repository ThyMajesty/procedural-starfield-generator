extends VBoxContainer

#  ¯\_(ツ)_/¯

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

var file_manager: FileManager

func _ready() -> void:
	SM.build_widgets(settings_panel)

	SM.wire_widgets(settings_panel)

	generate_button.pressed.connect(generate)

	file_manager = FileManager.new(self)
	save_button.pressed.connect(_on_save_pressed)

func _on_save_pressed() -> void:
	# mock setting for now 
	file_manager.request_save(_image, SM.s.seed_value, {})


func _build_info_label() -> void:
	info_label.text = "Elapsed: " + str(time_last_elapsed) + "ms"


#TODO: move GPU stuff to a separate class

func generate() -> void:
	var time_start = Time.get_ticks_msec()
	if SM.s.use_random_seed:
		SM.s.seed_value = randi()

	_image = Image.create(SM.s.resolution, SM.s.resolution, false, Image.FORMAT_RGBA8)
	var data := _bake_gpu()

	_image.set_data(SM.s.resolution, SM.s.resolution, false, Image.FORMAT_RGBA8, data)
	_texture = ImageTexture.create_from_image(_image)

	sprite_2d.texture = _texture
	var time_end = Time.get_ticks_msec()
	time_last_elapsed = time_end - time_start

	_build_info_label()


func _build_push_constant_star_gen(attempt_count: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	buf.put_32(attempt_count)
	buf.put_32(SM.s.star_count)       # max_stars (buffer capacity)
	buf.put_32(SM.s.resolution)
	buf.put_32(SM.s.seed_value)

	buf.put_float(SM.s.density_noise_scale)
	buf.put_float(SM.s.density_bias)
	buf.put_32(1 if SM.s.use_density_noise else 0)
	buf.put_float(SM.s.brightness_power)

	buf.put_float(SM.s.min_brightness)
	buf.put_float(SM.s.max_brightness)
	buf.put_float(SM.s.min_radius)
	buf.put_float(SM.s.max_radius)

	buf.put_32(1 if SM.s.size_follows_brightness else 0)
	buf.put_32(1 if SM.s.use_color_variation else 0)
	buf.put_float(SM.s.warm_chance)
	buf.put_float(SM.s.blue_chance)

	buf.put_float(SM.s.giant_chance)
	buf.put_float(SM.s.giant_size_multiplier)
	buf.put_float(0.0)
	buf.put_float(0.0)

	return buf.data_array

func _build_nebula_color_buffer() -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	for c in SM.s._collect_nebula_colors():
		buf.put_float(c.r)
		buf.put_float(c.g)
		buf.put_float(c.b)
		buf.put_float(c.a)

	return buf.data_array

func _build_push_constant_nebula(color_count: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	buf.put_float(SM.s.nebula_scale)
	buf.put_32(SM.s.nebula_octaves)
	buf.put_float(SM.s.nebula_intensity)
	buf.put_32(SM.s.seed_value)

	buf.put_32(color_count)
	buf.put_float(float(SM.s.resolution))
	buf.put_float(SM.s.nebula_warp_strength)
	buf.put_float(SM.s.nebula_warp_scale)

	buf.put_float(SM.s.background_color.r)
	buf.put_float(SM.s.background_color.g)
	buf.put_float(SM.s.background_color.b)
	buf.put_float(SM.s.background_color.a)

	buf.put_32(1 if SM.s.use_nebula else 0)
	buf.put_float(SM.s.nebula_dist_scale)
	buf.put_32(SM.s.nebula_dist_octaves)
	buf.put_float(SM.s.nebula_dist_strength)

	buf.put_float(SM.s.nebula_curl_scale)
	buf.put_float(SM.s.nebula_curl_strength)
	buf.put_32(SM.s.nebula_curl_octaves)
	buf.put_float(SM.s.nebula_curl_eps)

	return buf.data_array

func _build_push_constant_stars(star_count_actual: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false

	buf.put_32(star_count_actual)
	buf.put_32(SM.s.resolution)
	buf.put_float(0.0)
	buf.put_float(0.0)

	return buf.data_array

func _bake_gpu() -> PackedByteArray:
	var rd := RenderingServer.create_local_rendering_device()

	# shared output image
	var fmt := RDTextureFormat.new()
	fmt.width = SM.s.resolution
	fmt.height = SM.s.resolution
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
	var color_count := SM.s.nebula_color_count
	var neb_push := _build_push_constant_nebula(color_count)

	# star generation pass
	var attempt_count := SM.s.star_count * 20
	var gen_shader := rd.shader_create_from_spirv(load("res://shaders/compute/stars_generate.glsl").get_spirv())

	var counter_bytes := PackedByteArray()
	counter_bytes.resize(4)
	var counter_buf := rd.storage_buffer_create(4, counter_bytes)

	var star_buf := rd.storage_buffer_create(SM.s.star_count * 32)

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
	rd.compute_list_dispatch(cl, ceili(SM.s.resolution / 8.0), ceili(SM.s.resolution / 8.0), 1)

	rd.compute_list_bind_compute_pipeline(cl, gen_pipeline)
	rd.compute_list_bind_uniform_set(cl, gen_set, 0)
	rd.compute_list_set_push_constant(cl, gen_push, gen_push.size())
	rd.compute_list_dispatch(cl, ceili(attempt_count / 64.0), 1, 1)

	rd.compute_list_end()
	rd.submit()
	rd.sync()

	var count_data := rd.buffer_get_data(counter_buf)
	var star_count_actual: int = mini(count_data.decode_u32(0), SM.s.star_count)

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
