extends Node3D

@onready var joueur = $Joueur
@onready var vie_label: Label = $VieLabel
@onready var bouton_test: Button = $BoutonTest

func _ready() -> void:
	_maj_vies(joueur.vies)
	joueur.vie_perdue.connect(_maj_vies)
	joueur.mort.connect(_on_joueur_mort)
	bouton_test.pressed.connect(joueur.perdre_vie)

func _maj_vies(vies: int) -> void:
	vie_label.text = "Vies : %d" % vies

func _on_joueur_mort() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://game_over.tscn")
