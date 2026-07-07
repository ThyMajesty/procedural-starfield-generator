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

var s: PSG_Settings = PSG_Settings.new()

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

func _test() -> void:
	print(to_dict())

func to_dict(serialize: bool = true) -> Dictionary:
	var d := {}

	for cfg in widget_config:
		if cfg.type not in ["bool", "color", "float", "int"]: continue
		if serialize and not cfg.get("serializable", true): continue
		d[cfg.key] = s[cfg.key]

	return d
