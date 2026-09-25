extends Node3D
class_name Bombe

@export var taille_case: float = 2.0

@export var portee: int = 2

@export var delai_explosion: float = 2.0

@export var texture_bombe: Texture2D

@onready var timer: Timer = $Timer
@onready var mesh: MeshInstance3D = $MeshInstance3D

const GROUPE_MUR_INDESTRUCTIBLE := "mur_indestructible"
const GROUPE_MUR_DESTRUCTIBLE := "mur_destructible"
const GROUPE_JOUEUR := "joueur"

signal bombe_explosee(position_globale: Vector3)

static func case_contient_mur(pos: Vector3, monde: World3D, taille: float) -> bool:
	var space_state := monde.direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(taille * 0.9, 100.0, taille * 0.9)
	params.shape = forme
	params.transform = Transform3D(Basis(), pos)
	params.collide_with_bodies = true
	params.collide_with_areas = true

	var resultats := space_state.intersect_shape(params, 8)
	for res in resultats:
		var corps = res["collider"]
		if corps.is_in_group(GROUPE_MUR_INDESTRUCTIBLE) or corps.is_in_group(GROUPE_MUR_DESTRUCTIBLE):
			return true
	return false

func _ready() -> void:
	if texture_bombe:
		_appliquer_texture(texture_bombe)

	timer.wait_time = delai_explosion
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	timer.start()
	_animer_clignotement()

func set_texture(tex: Texture2D) -> void:
	texture_bombe = tex
	if mesh:
		_appliquer_texture(tex)

func _appliquer_texture(tex: Texture2D) -> void:
	var materiau := StandardMaterial3D.new()
	materiau.albedo_texture = tex
	mesh.material_override = materiau

func _on_timeout() -> void:
	exploser()

func exploser() -> void:
	var cases_touchees: Array[Vector3] = [global_position]

	var directions := [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]

	for direction in directions:
		for i in range(1, portee + 1):
			var pos_case: Vector3 = global_position + direction * taille_case * i
			var resultat := _analyser_case(pos_case)

			if resultat == "indestructible":
				break 

			cases_touchees.append(pos_case)

			if resultat == "destructible":
				break

	for pos in cases_touchees:
		_declencher_effet_case(pos)

	bombe_explosee.emit(global_position)
	queue_free()

func _analyser_case(pos: Vector3) -> String:
	var space_state := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(taille_case * 0.9, 100.0, taille_case * 0.9)
	params.shape = forme
	params.transform = Transform3D(Basis(), pos)
	params.collide_with_areas = true
	params.collide_with_bodies = true

	var resultats := space_state.intersect_shape(params, 8)

	for res in resultats:
		var corps = res["collider"]
		if corps.is_in_group(GROUPE_MUR_INDESTRUCTIBLE):
			return "indestructible"
		elif corps.is_in_group(GROUPE_MUR_DESTRUCTIBLE):
			corps.queue_free() 
			return "destructible"
		elif corps.is_in_group(GROUPE_JOUEUR):
			if corps.has_method("subir_degats"):
				corps.subir_degats()

	return "libre"

func _declencher_effet_case(pos: Vector3) -> void:
	print("Explosion en : ", pos)

func _animer_clignotement() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.3)
	tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
