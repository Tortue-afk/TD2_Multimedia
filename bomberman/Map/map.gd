extends Node3D

@export var taille_case = 1.0

var scene_sol = preload("res://Map/sol.tscn")
var scene_mur_indestructible = preload("res://Map/mur_indestructible.tscn")
var scene_mur_destructible = preload("res://Map/mur_destructible.tscn")

var grille = [
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 2, 2, 2, 0, 0, 0, 1],
	[1, 0, 1, 2, 1, 2, 1, 2, 1, 0, 1],
	[1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 1],
	[1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1],
	[1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 1],
	[1, 0, 1, 2, 1, 2, 1, 2, 1, 0, 1],
	[1, 0, 0, 0, 2, 2, 2, 0, 0, 0, 1],
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

func _ready():
	construire_niveau()

func construire_niveau():
	for z in range(grille.size()):
		for x in range(grille[z].size()):
			var position_case = Vector3(x * taille_case, 0, z * taille_case)
			
			var sol = scene_sol.instantiate()
			sol.position = position_case
			add_child(sol)
			
			var type_case = grille[z][x]
			if type_case == 1:
				var mur = scene_mur_indestructible.instantiate()
				mur.position = position_case
				add_child(mur)
			elif type_case == 2:
				var mur = scene_mur_destructible.instantiate()
				mur.position = position_case
				add_child(mur)
