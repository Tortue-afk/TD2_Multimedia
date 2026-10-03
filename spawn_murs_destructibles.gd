extends Node3D

@export var grille: GridMap
@export var chance_apparition: float = 0.6
@export var distance_min_joueur: float = 4.0
@export var nom_tuile_sol: String = "MeshSol"
@export var nom_tuile_mur_destructible: String = "MeshMurDestructible"
@export var chance_bonus: float = 0.15
@export var scenes_bonus: Array[PackedScene] = []

var positions_fixes: Array[Vector3] = [
	Vector3(0, -1.5, 0),
]

var cases_avec_bonus: Dictionary = {}

func _ready():
	generer()

func generer():
	cases_avec_bonus.clear()

	var id_sol := grille.mesh_library.find_item_by_name(nom_tuile_sol)
	var id_mur := grille.mesh_library.find_item_by_name(nom_tuile_mur_destructible)

	if id_sol == -1 or id_mur == -1:
		push_error("Tuile introuvable : vérifie les noms sol/mur destructible")
		return

	var cases_fixes: Array[Vector3i] = []
	for pos in positions_fixes:
		var c := grille.local_to_map(grille.to_local(pos))
		grille.set_cell_item(c, id_mur)
		cases_fixes.append(c)
		_tenter_assigner_bonus(c)

	var joueurs = get_tree().get_nodes_in_group("joueur")

	for case in grille.get_used_cells_by_item(id_sol):
		if case in cases_fixes:
			continue

		var centre = grille.to_global(grille.map_to_local(case))

		var trop_pres = false
		for j in joueurs:
			var ecart = Vector2(centre.x - j.global_position.x, centre.z - j.global_position.z)
			if ecart.length() < distance_min_joueur:
				trop_pres = true
				break

		if trop_pres:
			continue

		if randf() < chance_apparition:
			grille.set_cell_item(case, id_mur)
			_tenter_assigner_bonus(case)

func _tenter_assigner_bonus(case: Vector3i) -> void:
	if scenes_bonus.is_empty():
		return
	if randf() < chance_bonus:
		var scene_choisie: PackedScene = scenes_bonus[randi() % scenes_bonus.size()]
		cases_avec_bonus[case] = scene_choisie

func bonus_pour_case(case: Vector3i) -> PackedScene:
	return cases_avec_bonus.get(case, null)

func retirer_bonus(case: Vector3i) -> void:
	cases_avec_bonus.erase(case)
