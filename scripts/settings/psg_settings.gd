class_name PSG_Settings
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
