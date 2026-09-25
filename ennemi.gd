extends CharacterBody3D

@export var vitesse = 2.0
@export var taille_case = 1.0

var direction_actuelle = Vector3.ZERO
var directions_possibles = [
	Vector3(1, 0, 0),
	Vector3(-1, 0, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, -1),
]

func _ready():
	choisir_nouvelle_direction()

func _physics_process(delta):
	velocity = direction_actuelle * vitesse
	
	var etait_bloque = velocity.length() > 0 and not test_move(global_transform, direction_actuelle * 0.1)
	
	move_and_slide()
	
	# Si l'ennemi vient de percuter un mur, on choisit une nouvelle direction
	if get_slide_collision_count() > 0:
		choisir_nouvelle_direction()

func choisir_nouvelle_direction():
	var directions_valides = []
	
	for dir in directions_possibles:
		if test_move(global_transform, dir * taille_case * 0.5):
			continue
		directions_valides.append(dir)
	
	if directions_valides.size() > 0:
		direction_actuelle = directions_valides[randi() % directions_valides.size()]
	else:
		direction_actuelle = Vector3.ZERO
