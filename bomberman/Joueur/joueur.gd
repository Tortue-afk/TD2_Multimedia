extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var animated_sprite_3d = $AnimatedSprite3D  # Assure-toi que le nœud s'appelle bien "AnimatedSprite3D"

func _physics_process(delta: float) -> void:
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Mettre à jour les animations en fonction de la direction
	if direction != Vector3.ZERO:
		# Le personnage est en mouvement
		if input_dir.y > 0:
			# Mouvement vers l'avant (haut)
			animated_sprite_3d.play("run_bottom")
		elif input_dir.y < 0:
			# Mouvement vers l'arrière (bas)
			animated_sprite_3d.play("run_top")
		elif input_dir.x > 0:
			# Mouvement vers la droite
			animated_sprite_3d.play("run_right")
		elif input_dir.x < 0:
			# Mouvement vers la gauche
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
