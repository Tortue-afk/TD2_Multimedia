extends Node3D

@onready var joueur = $Joueur
@onready var joueur2 = $Joueur2
@onready var vie_label: Label = $VieLabel
@onready var vie_label_j2: Label = $VieLabelJ2
@onready var player2_label: Label = $Player2Label
@onready var bouton_test: Button = $BoutonTest
@onready var bouton_test_j2: Button = $BoutonTestJ2

var temps_clignotement := 0.0
var joueur2_actif := false
var partie_terminee := false

func _ready() -> void:
	joueur2.desactiver()
	player2_label.visible = true
	vie_label_j2.visible = false
	bouton_test_j2.visible = false

	_maj_vies(joueur.vies)
	joueur.vie_perdue.connect(_maj_vies)
	joueur.mort.connect(_on_joueur_mort)
	joueur2.mort.connect(_on_joueur_mort)
	bouton_test.pressed.connect(joueur.perdre_vie)
	bouton_test_j2.pressed.connect(joueur2.perdre_vie)

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
	bouton_test_j2.visible = true

	vie_label_j2.visible = true
	_maj_vies_j2(joueur2.vies)
	joueur2.vie_perdue.connect(_maj_vies_j2)

func _maj_vies(vies: int) -> void:
	vie_label.text = "J1 - Vies : %d" % vies

func _maj_vies_j2(vies: int) -> void:
	vie_label_j2.text = "J2 - Vies : %d" % vies

func _on_joueur_mort() -> void:
	if partie_terminee:
		return

	if not joueur2_actif:
		# Solo : toujours une défaite
		partie_terminee = true
		Resultat.vies_j1 = joueur.vies
		Resultat.multijoueur = false
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://game_over.tscn")
		return

	# Multijoueur : il y a forcément un résultat
	var j1_vivant : bool = joueur.vies > 0
	var j2_vivant : bool = joueur2.vies > 0

	if j1_vivant and not j2_vivant:
		_terminer_partie("J1")
	elif j2_vivant and not j1_vivant:
		_terminer_partie("J2")
	elif not j1_vivant and not j2_vivant:
		_terminer_partie("Egalite")
	# si les deux sont encore vivants, ce signal venait d'un joueur qui a encore des vies : rien à faire

func _terminer_partie(vainqueur: String) -> void:
	partie_terminee = true

	Resultat.vies_j1 = joueur.vies
	Resultat.vies_j2 = joueur2.vies
	Resultat.multijoueur = true
	Resultat.vainqueur = vainqueur

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://victory.tscn")
