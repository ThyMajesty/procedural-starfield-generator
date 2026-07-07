class_name PSG_SettingsManager
extends Node

# ui typed config driving both widget generation and value application
# type: "bool" | "color" | "int" | "float"
var widget_config: Array[Dictionary] = [
	{key = "resolution", type = "int", min_value = 256, max_value = 16384, step = 256, view_name = "Resolution"},
	{key = "star_count", type = "int", min_value = 100, max_value = 1000000, step = 1},
	{key = "seed_value", type = "int", min_value = 0, max_value = 1000000, step = 1},
	{key = "use_random_seed", type = "bool"},

	{key = "use_density_noise", type = "bool"},
	{key = "density_noise_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1},
	{key = "density_bias", type = "float", min_value = 0.1, max_value = 5.0, step = 0.1},

	{key = "brightness_power", type = "float", min_value = 0.5, max_value = 32.0, step = 0.1},
	{key = "min_brightness", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01},
	{key = "max_brightness", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01},

	{key = "min_radius", type = "float", min_value = 0.1, max_value = 10.0, step = 0.1},
	{key = "max_radius", type = "float", min_value = 0.1, max_value = 10.0, step = 0.1},
	{key = "size_follows_brightness", type = "bool"},

	{key = "giant_chance", type = "float", min_value = 0.0, max_value = 0.1, step = 0.001},
	{key = "giant_size_multiplier", type = "float", min_value = 1.0, max_value = 10.0, step = 0.1},

	{key = "use_color_variation", type = "bool"},
	{key = "warm_chance", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01},
	{key = "blue_chance", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01},

	{key = "background_color", type = "color"},

	{key = "use_nebula", type = "bool"},
	{key = "nebula_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1},
	{key = "nebula_octaves", type = "int", min_value = 1, max_value = 16, step = 1},
	{key = "nebula_intensity", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01},
	{key = "nebula_color_count", type = "int", min_value = 1, max_value = 5, step = 1},

	{key = "nebula_color_1", type = "color"},
	{key = "nebula_color_2", type = "color"},
	{key = "nebula_color_3", type = "color"},
	{key = "nebula_color_4", type = "color"},
	{key = "nebula_color_5", type = "color"},

	{key = "nebula_warp_strength", type = "float", min_value = 0.0, max_value = 2000.0, step = 1.0},
	{key = "nebula_warp_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1},

	{key = "nebula_dist_scale", type = "float", min_value = 0.05, max_value = 10.0, step = 0.05},
	{key = "nebula_dist_octaves", type = "int", min_value = 1, max_value = 8, step = 1},
	{key = "nebula_dist_strength", type = "float", min_value = 0.0, max_value = 1.0, step = 0.01},

	{key = "nebula_curl_scale", type = "float", min_value = 0.1, max_value = 20.0, step = 0.1},
	{key = "nebula_curl_strength", type = "float", min_value = 0.0, max_value = 100000.0, step = 5.0},
	{key = "nebula_curl_octaves", type = "int", min_value = 1, max_value = 8, step = 1},
	{key = "nebula_curl_eps", type = "float", min_value = 0.1, max_value = 10.0, step = 0.1},
]

var widget_nodes: Array
var widget_dict: Dictionary

var s := PSG_Settings.new()

func build_widgets(parent_node: Control) -> void:
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
		# view name
		if cfg.has("view_name"):
			node.view_name = cfg.view_name

		if cfg.type in ["float", "int"]:
			if cfg.has("min_value"): node.min_value = cfg.min_value
			if cfg.has("max_value"): node.max_value = cfg.max_value
			if cfg.has("step"): node.step = cfg.step

		parent_node.add_child(node)

func wire_widgets(parent_node: Control) -> void:
	var all_widgets = parent_node.get_tree().get_nodes_in_group("UIWidget")
	print(all_widgets.size())
	for uiw_node in all_widgets:
		if uiw_node is UIWidget:
			var key = uiw_node.property_name
			widget_dict[key] = uiw_node
			widget_dict[key].value_changed.connect(s._on_changed.bind(key))
			widget_dict[key]._set_value(s[key])


class PSG_Settings:
	signal on_changed(new_value: Variant, key: String)

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

	func _on_changed(value, key: String, emit = true) -> void:
		if self[key] == value: return
		self[key] = value
		#print("_value_changed " + str(key) + " " + str(value) + " | emit: " + str(emit))
		if emit: on_changed.emit(value, key)
