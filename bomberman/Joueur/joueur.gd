extends CharacterBody3D

signal vie_perdue(vies_restantes: int)
signal mort

const SPEED = 5.0

@export var vies_max: int = 3
var vies: int
var position_depart: Vector3

@onready var animated_sprite_3d = $AnimatedSprite3D

func _ready() -> void:
	vies = vies_max
	position_depart = global_position

func _physics_process(delta: float) -> void:
	# Direction voulue par le joueur
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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
