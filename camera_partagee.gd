extends Camera3D

@export var joueur: Node3D
@export var joueur2: Node3D
@export var hauteur_base: float = 4.0
@export var recul_base: float = 2.0
@export var zoom_min: float = 1.0
@export var zoom_max: float = 10.0
@export var vitesse_suivi: float = 4.0
@export var angle_x_degres: float = -60.0

var joueur2_actif := false

func activer(j2_actif: bool) -> void:
	joueur2_actif = j2_actif
	rotation_degrees.x = angle_x_degres
	rotation_degrees.y = 0.0
	rotation_degrees.z = 0.0
	make_current()

func _process(delta: float) -> void:
	if not (joueur and is_instance_valid(joueur)):
		return

	var cible: Vector3
	var facteur_zoom := 0.0

	if joueur2_actif and joueur2 and is_instance_valid(joueur2):
		cible = (joueur.global_position + joueur2.global_position) / 2.0
		var distance := joueur.global_position.distance_to(joueur2.global_position)
		facteur_zoom = clamp(
			(distance - zoom_min) / (zoom_max - zoom_min), 0.0, 1.0)
	else:
		cible = joueur.global_position

	var hauteur := hauteur_base + facteur_zoom * 6.0
	var recul := recul_base + facteur_zoom * 5.0

	var position_voulue := cible + Vector3(0, hauteur, recul)
	global_position = global_position.lerp(position_voulue, vitesse_suivi * delta)
