extends Node3D
class_name Bombe

@export var taille_case: float = 2.0

@export var portee: int = 1

@export var delai_explosion: float = 2.0

@export var texture_bombe: Texture2D

@export var items_indestructibles: Array[int] = [1]
@export var items_destructibles: Array[int] = [0]

@onready var timer: Timer = $Timer
@onready var mesh: Sprite3D = $Sprite3D

var joueurs_touches: Array[Node] = []

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
	joueurs_touches.clear()
	var cases_touchees: Array[Vector3] = [global_position]
	_analyser_case(global_position)   # la case de la bombe est touchée aussi

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

	for j in joueurs_touches:
		j.perdre_vie()

	bombe_explosee.emit(global_position)
	queue_free()

func _grille() -> GridMap:
	return get_tree().current_scene.get_node_or_null("MapGrid") as GridMap
	
func _analyser_case(pos: Vector3) -> String:
	# 1) Les murs : lus directement dans le GridMap
	var grille := _grille()
	if grille:
		var c := grille.local_to_map(grille.to_local(pos))
		for y in range(c.y - 2, c.y + 3):
			var cellule := Vector3i(c.x, y, c.z)
			var item := grille.get_cell_item(cellule)
			if item == GridMap.INVALID_CELL_ITEM:
				continue
			print("GridMap : item ", item, " en ", cellule)   # temporaire
			if item in items_indestructibles:
				return "indestructible"
			if item in items_destructibles:
				grille.set_cell_item(cellule, GridMap.INVALID_CELL_ITEM)
				return "destructible"

	# 2) Les joueurs présents dans la case
	var params := PhysicsShapeQueryParameters3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(taille_case * 0.9, 100.0, taille_case * 0.9)
	params.shape = forme
	params.transform = Transform3D(Basis(), pos)
	params.collide_with_bodies = true

	for res in get_world_3d().direct_space_state.intersect_shape(params, 16):
		var corps = res["collider"]
		if corps.is_in_group(GROUPE_JOUEUR) and not joueurs_touches.has(corps):
			joueurs_touches.append(corps)

	return "libre"

func _declencher_effet_case(pos: Vector3) -> void:
	var flamme := MeshInstance3D.new()
	var boite := BoxMesh.new()
	boite.size = Vector3(taille_case * 0.9, 0.4, taille_case * 0.9)
	flamme.mesh = boite

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.1, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flamme.material_override = mat

	# Dans la scène, pas dans la bombe : la bombe est supprimée juste après l'explosion
	get_tree().current_scene.add_child(flamme)
	flamme.global_position = pos + Vector3(0, 0.2, 0)
	flamme.scale = Vector3(0.2, 0.2, 0.2)
	flamme.visible = false

	# Les flammes partent du centre et s'étendent vers l'extérieur
	var delai := pos.distance_to(global_position) / taille_case * 0.06

	var tween := flamme.create_tween()
	tween.tween_interval(delai)
	tween.tween_callback(flamme.show)
	tween.tween_property(flamme, "scale", Vector3.ONE, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(flamme.queue_free)

func _animer_clignotement() -> void:
	var base := mesh.scale
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(mesh, "scale", base * 1.15, 0.3)
	tween.tween_property(mesh, "scale", base, 0.3)
