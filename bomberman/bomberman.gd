extends Node3D

@onready var joueur = $Joueur
@onready var joueur2 = $Joueur2
@onready var vie_label: Label = $VieLabel
@onready var player2_label: Label = $Player2Label
@onready var bouton_test: Button = $BoutonTest

var temps_clignotement := 0.0
var joueur2_actif := false
var joueurs_vivants := 1

func _ready() -> void:
	joueur2.desactiver()
	player2_label.visible = true

	_maj_vies(joueur.vies)
	joueur.vie_perdue.connect(_maj_vies)
	joueur.mort.connect(_on_joueur_mort)
	joueur2.mort.connect(_on_joueur_mort)
	bouton_test.pressed.connect(joueur.perdre_vie)

func _process(delta: float) -> void:
	if joueur2_actif:
		return

	temps_clignotement += delta
	if temps_clignotement >= 0.5:
		temps_clignotement = 0.0
		player2_label.visible = not player2_label.visible

	if Input.is_action_just_pressed("p2_join"):
		_activer_joueur2()

func _activer_joueur2() -> void:
	joueur2_actif = true
	joueur2.activer()
	player2_label.visible = false
	joueurs_vivants += 1

func _maj_vies(vies: int) -> void:
	vie_label.text = "Vies : %d" % vies

func _on_joueur_mort() -> void:
	joueurs_vivants -= 1
	if joueurs_vivants > 0:
		return
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://game_over.tscn")
