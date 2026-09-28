extends CharacterBody3D

var grille: GridMap
@export var vitesse = 2.0

const DIRECTIONS = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]

var cible = Vector3.ZERO
var en_mouvement = false
var derniere_direction = Vector3.ZERO

@onready var animated_sprite_3d = $AnimatedSprite3D


func _ready():
	grille = get_tree().current_scene.get_node("MapGrid")

	var centre = centre_de_case(global_position)
	global_position = Vector3(centre.x, global_position.y, centre.z)


func _physics_process(delta):
	if not en_mouvement:
		choisir_prochaine_case()
		animated_sprite_3d.play("idle_front")
		return

	var vers_cible = cible - global_position
	vers_cible.y = 0

	# Animation selon la direction
	if abs(vers_cible.x) > abs(vers_cible.z):
		if vers_cible.x > 0:
			animated_sprite_3d.play("run_right")
		else:
			animated_sprite_3d.play("run_left")
	else:
		if vers_cible.z > 0:
			animated_sprite_3d.play("run_bottom")
		else:
			animated_sprite_3d.play("run_top")

	# Arrivé au centre de la case
	if vers_cible.length() <= vitesse * delta:
		global_position.x = cible.x
		global_position.z = cible.z
		en_mouvement = false

		# Animation idle correspondant à la dernière direction
		if derniere_direction == Vector3.RIGHT:
			animated_sprite_3d.play("idle_right")
		elif derniere_direction == Vector3.LEFT:
			animated_sprite_3d.play("idle_left")
		elif derniere_direction == Vector3.FORWARD:
			animated_sprite_3d.play("idle_back")
		elif derniere_direction == Vector3.BACK:
			animated_sprite_3d.play("idle_front")

		return

	velocity = vers_cible.normalized() * vitesse
	move_and_slide()

	# Quelque chose bloque le chemin
	if get_slide_collision_count() > 0:
		cible = centre_de_case(global_position)
		en_mouvement = true


func choisir_prochaine_case():
	var taille = grille.cell_size.x
	var candidates = DIRECTIONS.duplicate()
	candidates.shuffle()

	# On évite de faire demi-tour, sauf en cul-de-sac
	if candidates.has(-derniere_direction):
		candidates.erase(-derniere_direction)
		candidates.append(-derniere_direction)

	for dir in candidates:
		if not test_move(global_transform, dir * taille):
			cible = centre_de_case(global_position + dir * taille)
			derniere_direction = dir
			en_mouvement = true
			return


func centre_de_case(pos: Vector3) -> Vector3:
	var case_grille = grille.local_to_map(grille.to_local(pos))
	var centre = grille.to_global(grille.map_to_local(case_grille))
	return Vector3(centre.x, global_position.y, centre.z)
