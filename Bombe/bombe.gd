extends Node3D
class_name Bombe

@export var taille_case: float = 2.0
@export var portee: int = 1
@export var delai_explosion: float = 2.0
@export var texture_bombe: Texture2D
@export var items_indestructibles: Array[int] = [1]
@export var items_destructibles: Array[int] = [0]
@export var nom_tuile_sol: String = "MeshSol"
@export var vitesse_glissement: float = 6.0

@onready var timer: Timer = $Timer
@onready var mesh: Sprite3D = $Sprite3D
@onready var solide: StaticBody3D = $Solide
@onready var zone_detection_ennemi: Area3D = $ZoneDetectionEnnemi

var glissante := false
var direction_glissement := Vector3.ZERO
var cible_glissement := Vector3.ZERO

var joueurs_touches: Array[Node] = []

const GROUPE_ENNEMI := "ennemi"
var ennemis_touches: Array[Node] = []

const GROUPE_MUR_INDESTRUCTIBLE := "mur_indestructible"
const GROUPE_MUR_DESTRUCTIBLE := "mur_destructible"
const GROUPE_JOUEUR := "joueur"

signal bombe_explosee(position_globale: Vector3)

var proprietaire: Node = null

var a_explose := false

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

func _on_ennemi_touche(corps: Node) -> void:
	if a_explose:
		return
	exploser()

func _ready() -> void:
	add_to_group("bombe")
	solide.get_child(0).disabled = true
	_tenter_activer_collision()

	zone_detection_ennemi.body_entered.connect(_on_ennemi_touche)

	if texture_bombe:
		_appliquer_texture(texture_bombe)

	timer.wait_time = delai_explosion
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	timer.start()
	_animer_clignotement()

func _tenter_activer_collision() -> void:
	get_tree().create_timer(0.4).timeout.connect(func():
		if not is_instance_valid(self) or not is_inside_tree() or a_explose:
			return
		var occupee := false
		for corps in get_tree().get_nodes_in_group("joueur"):
			var ecart: Vector3 = corps.global_position - global_position
			ecart.y = 0
			if ecart.length() < taille_case * 0.45:
				occupee = true
				break
		if occupee:
			_tenter_activer_collision()
		else:
			solide.get_child(0).disabled = false
	)

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
	if a_explose:
		return
	a_explose = true

	if not is_inside_tree():
		return

	joueurs_touches.clear()
	ennemis_touches.clear()
	var cases_touchees: Array[Vector3] = [global_position]
	_analyser_case(global_position)

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

	for e in ennemis_touches:
		if is_instance_valid(e):
			e.mourir()

	if ennemis_touches.size() > 0:
		var niveau := get_tree().current_scene
		if niveau.has_method("_on_ennemis_tues"):
			niveau._on_ennemis_tues(proprietaire, ennemis_touches.size())

	if is_inside_tree():
		bombe_explosee.emit(global_position)
	queue_free()

func _grille() -> GridMap:
	return get_tree().current_scene.get_node_or_null("MapGrid") as GridMap

func _analyser_case(pos: Vector3) -> String:
	var grille := _grille()
	if grille:
		var c := grille.local_to_map(grille.to_local(pos))
		for y in range(c.y - 2, c.y + 3):
			var cellule := Vector3i(c.x, y, c.z)
			var item := grille.get_cell_item(cellule)
			if item == GridMap.INVALID_CELL_ITEM:
				continue
			if item in items_indestructibles:
				return "indestructible"
			if item in items_destructibles:
				var id_sol := grille.mesh_library.find_item_by_name(nom_tuile_sol)
				grille.set_cell_item(cellule, GridMap.INVALID_CELL_ITEM)
				if id_sol != -1:
					grille.set_cell_item(cellule, id_sol)
				_faire_apparaitre_bonus(cellule, pos)
				return "destructible"

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
		elif corps.is_in_group(GROUPE_ENNEMI) and not ennemis_touches.has(corps):
			ennemis_touches.append(corps)

	return "libre"

func _faire_apparaitre_bonus(cellule: Vector3i, pos: Vector3) -> void:
	var spawn_mur := get_tree().current_scene.get_node_or_null("SpawnMursDestructibles")
	if not spawn_mur:
		return

	var scene_bonus: PackedScene = spawn_mur.bonus_pour_case(cellule)
	if scene_bonus == null:
		return

	spawn_mur.retirer_bonus(cellule)

	var bonus := scene_bonus.instantiate()
	get_tree().current_scene.add_child(bonus)
	bonus.global_position = Vector3(pos.x, pos.y, pos.z)

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

	get_tree().current_scene.add_child(flamme)
	flamme.global_position = pos + Vector3(0, 0.2, 0)
	flamme.scale = Vector3(0.2, 0.2, 0.2)
	flamme.visible = false

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

func pousser(direction: Vector3) -> void:
	if glissante:
		return

	var dir := Vector3.ZERO
	if abs(direction.x) > abs(direction.z):
		dir = Vector3(sign(direction.x), 0, 0)
	else:
		dir = Vector3(0, 0, sign(direction.z))

	_tenter_avancer(dir)

func _tenter_avancer(dir: Vector3) -> void:
	var prochaine := global_position + dir * taille_case
	if _case_bloquee(prochaine):
		exploser()
		return

	direction_glissement = dir
	cible_glissement = prochaine
	glissante = true

func _case_bloquee(pos: Vector3) -> bool:
	var grille := _grille()
	if grille:
		var c := grille.local_to_map(grille.to_local(pos))
		for y in range(c.y - 2, c.y + 3):
			var item := grille.get_cell_item(Vector3i(c.x, y, c.z))
			if item == GridMap.INVALID_CELL_ITEM:
				continue
			if item in items_indestructibles or item in items_destructibles:
				return true

	return _autre_bombe_sur_case(pos)

func _autre_bombe_sur_case(pos: Vector3) -> bool:
	for bombe in get_tree().get_nodes_in_group("bombe"):
		if bombe == self or not is_instance_valid(bombe):
			continue
		var ecart: Vector3 = bombe.global_position - pos
		ecart.y = 0
		if ecart.length() < taille_case * 0.5:
			return true
	return false

func _physics_process(delta: float) -> void:
	if a_explose:
		return

	if not glissante:
		return

	var vers_cible := cible_glissement - global_position
	vers_cible.y = 0

	if vers_cible.length() <= vitesse_glissement * delta:
		global_position.x = cible_glissement.x
		global_position.z = cible_glissement.z
		glissante = false
		_tenter_avancer(direction_glissement)
	else:
		global_position += vers_cible.normalized() * vitesse_glissement * delta
