extends Node3D

@export var grille: GridMap
@export var scene_ennemi: PackedScene
@export var nombre_ennemis = 3
@export var distance_min_joueur = 4.0
@export var nom_tuile_sol = "MeshSol"
@export var hauteur_par_defaut = 1.0
@export var decalage_hauteur = 0.0

func _ready():
	lancer_spawn()

func lancer_spawn():
	var id_sol = grille.mesh_library.find_item_by_name(nom_tuile_sol)
	if id_sol == -1:
		push_error("Tuile introuvable dans la MeshLibrary : " + nom_tuile_sol)
		return

	var joueurs = get_tree().get_nodes_in_group("joueur")

	# On prend la hauteur d'un joueur, il est déjà bien posé sur le sol
	var hauteur = hauteur_par_defaut
	if joueurs.size() > 0:
		hauteur = joueurs[0].global_position.y
	hauteur += decalage_hauteur

	var centres_libres = []
	for case in grille.get_used_cells_by_item(id_sol):
		# Case occupée si un mur est posé juste au-dessus du sol
		var au_dessus = case + Vector3i(0, 1, 0)
		if grille.get_cell_item(au_dessus) != GridMap.INVALID_CELL_ITEM:
			continue

		var centre = grille.to_global(grille.map_to_local(case))

		# On évite les cases proches des joueurs
		var trop_pres = false
		for j in joueurs:
			var ecart = Vector2(centre.x - j.global_position.x, centre.z - j.global_position.z)
			if ecart.length() < distance_min_joueur:
				trop_pres = true
				break

		if not trop_pres:
			centres_libres.append(centre)

	centres_libres.shuffle()

	for i in range(min(nombre_ennemis, centres_libres.size())):
		var ennemi = scene_ennemi.instantiate()
		ennemi.grille = grille
		ennemi.position = Vector3(centres_libres[i].x, hauteur, centres_libres[i].z)
		add_child(ennemi)
