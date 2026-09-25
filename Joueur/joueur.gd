extends CharacterBody3D

@export_enum("Joueur 1", "Joueur 2") var joueur := 0

signal vie_perdue(vies_restantes: int)
signal mort

const SPEED = 5.0

@export var vies_max: int = 3
var vies: int
var position_depart: Vector3
var prefixe_input := "ui"

var actif := true
var _layer_initial: int
var _mask_initial: int

@onready var animated_sprite_3d = $AnimatedSprite3D

func _ready() -> void:
	if joueur == 1:
		animated_sprite_3d.modulate = Color(0.3, 0.6, 1.0)
		prefixe_input = "p2"
	else:
		animated_sprite_3d.modulate = Color.WHITE
		prefixe_input = "ui"

	vies = vies_max
	position_depart = global_position
	_layer_initial = collision_layer
	_mask_initial = collision_mask

func _physics_process(delta: float) -> void:
	# Direction voulue par ce joueur (touches selon l'enum)
	var input_dir := Input.get_vector(
		prefixe_input + "_left", prefixe_input + "_right",
		prefixe_input + "_up", prefixe_input + "_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Mettre à jour les animations en fonction de la direction
	if direction != Vector3.ZERO:
		# Le personnage est en mouvement
		if input_dir.y > 0:
			animated_sprite_3d.play("run_bottom")
		elif input_dir.y < 0:
			animated_sprite_3d.play("run_top")
		elif input_dir.x > 0:
			animated_sprite_3d.play("run_right")
		elif input_dir.x < 0:
			animated_sprite_3d.play("run_left")
	else:
		# Le personnage est immobile
		if animated_sprite_3d.animation == "run_bottom":
			animated_sprite_3d.play("idle_front")
		elif animated_sprite_3d.animation == "run_right":
			animated_sprite_3d.play("idle_right")
		elif animated_sprite_3d.animation == "run_left":
			animated_sprite_3d.play("idle_left")
		elif animated_sprite_3d.animation == "run_top":
			animated_sprite_3d.play("idle_back")

	# Gérer le mouvement
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func perdre_vie() -> void:
	vies -= 1
	vie_perdue.emit(vies)
	if vies <= 0:
		set_physics_process(false)
		mort.emit()
	else:
		reapparaitre()

func reapparaitre() -> void:
	velocity = Vector3.ZERO
	global_position = position_depart

func desactiver() -> void:
	actif = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	collision_layer = 0
	collision_mask = 0

func activer() -> void:
	actif = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = _layer_initial
	collision_mask = _mask_initial
