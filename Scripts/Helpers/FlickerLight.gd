extends OmniLight

var base_energy
export var random_energy = 0.5

var noise
var anim = 0

func _ready():
	base_energy = light_energy

	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 0.1
	noise.persistence = 0.5

func _process(delta):
	light_energy = base_energy + noise.get_noise_2d(anim,0)*random_energy
	anim += delta