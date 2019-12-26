extends AudioStreamPlayer

var base_pitch
export var random_pitch = 0.025

var noise
var anim = 0

func _ready():
	base_pitch = self.pitch_scale

	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 2
	noise.period = 10
	noise.persistence = 0.5

func _process(delta):
	self.pitch_scale = base_pitch + noise.get_noise_2d(anim,0)*random_pitch
	anim += delta