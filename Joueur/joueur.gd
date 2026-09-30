extends CharacterBody3D

const BombeScene := preload("res://Bombe/Bombe.tscn")

@export_enum("Joueur 1", "Joueur 2") var joueur := 0

signal vie_perdue(vies_restantes: int)
signal mort
signal score_change(score: int)

const SPEED = 5.0

@export var vies_max: int = 3
var vies: int
var position_depart: Vector3
var prefixe_input := "ui"

var actif := true
var _layer_initial: int
var _mask_initial: int

var action_bombe := "ui_accept"

# --- Bonus ---
var bombes_posees: Array[Bombe] = []
var max_bombes := 1
var portee_bombes := 1

var score: int = 0
var invincible := false

@onready var animated_sprite_3d = $AnimatedSprite3D

func _ready() -> void:
	add_to_group("joueur")
	if joueur == 1:
		animated_sprite_3d.modulate = Color(0.3, 0.6, 1.0)
		prefixe_input = "p2"
		action_bombe = "p2_action"
	else:
		animated_sprite_3d.modulate = Color.WHITE
		prefixe_input = "ui"
		action_bombe = "p1_action"

	vies = vies_max
	position_depart = global_position
	_layer_initial = collision_layer
	_mask_initial = collision_mask

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector(
		prefixe_input + "_left", prefixe_input + "_right",
		prefixe_input + "_up", prefixe_input + "_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		if input_dir.y > 0:
			animated_sprite_3d.play("run_bottom")
		elif input_dir.y < 0:
			animated_sprite_3d.play("run_top")
		elif input_dir.x > 0:
			animated_sprite_3d.play("run_right")
		elif input_dir.x < 0:
			animated_sprite_3d.play("run_left")
	else:
		if animated_sprite_3d.animation == "run_bottom":
			animated_sprite_3d.play("idle_front")
		elif animated_sprite_3d.animation == "run_right":
			animated_sprite_3d.play("idle_right")
		elif animated_sprite_3d.animation == "run_left":
			animated_sprite_3d.play("idle_left")
		elif animated_sprite_3d.animation == "run_top":
			animated_sprite_3d.play("idle_back")

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# Poussée des bombes posées par ce joueur
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var corps = collision.get_collider()
		for b in bombes_posees:
			if not is_instance_valid(b):
				continue
			var solide = b.get_node_or_null("Solide")
			if solide != null and corps == solide:
				b.pousser(-collision.get_normal())

func perdre_vie() -> void:
	if invincible:
		return

	vies -= 1
	vie_perdue.emit(vies)
	if vies <= 0:
		set_physics_process(false)
		mort.emit()
	else:
		reapparaitre()
		invincible = true
		await get_tree().create_timer(1.0).timeout
		invincible = false

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(action_bombe):
		poser_bombe()

func poser_bombe() -> void:
	if vies <= 0:
		return

	# On retire de la liste les bombes déjà explosées
	var restantes: Array[Bombe] = []
	for b in bombes_posees:
		if is_instance_valid(b):
			restantes.append(b)
	bombes_posees = restantes

	if bombes_posees.size() >= max_bombes:
		return

	var bombe: Bombe = BombeScene.instantiate()
	bombe.portee = portee_bombes
	var taille_case := bombe.taille_case

	var pos_case := Vector3(
		(floor(global_position.x / taille_case) + 0.5) * taille_case,
		global_position.y,
		(floor(global_position.z / taille_case) + 0.5) * taille_case)

	# Empêche de poser 2 bombes sur la même case
	for b in bombes_posees:
		if b.global_position.distance_to(pos_case) < 0.1:
			bombe.queue_free()
			return

	get_tree().current_scene.add_child(bombe)
	bombe.global_position = pos_case
	bombe.proprietaire = self
	bombes_posees.append(bombe)

func ajouter_bombe() -> void:
	max_bombes += 1

func ajouter_portee() -> void:
	portee_bombes += 1

func ajouter_score(points: int) -> void:
	score += points
	score_change.emit(score)
