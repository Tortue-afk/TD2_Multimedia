extends Node3D

@onready var joueur = $Joueur
@onready var joueur2 = $Joueur2
@onready var vie_label: Label = $VieLabel
@onready var vie_label_j2: Label = $VieLabelJ2
@onready var player2_label: Label = $Player2Label
@onready var score_label: Label = $ScoreLabel
@onready var score_label_j2: Label = $ScoreLabelJ2
@onready var camera_partagee = $CameraPartagee


var temps_clignotement := 0.0
var joueur2_actif := false
var partie_terminee := false
var ennemis_restants := 0

func _ready() -> void:
	joueur2.desactiver()
	player2_label.visible = true
	vie_label_j2.visible = false
	score_label_j2.visible = false

	_maj_vies(joueur.vies)
	joueur.vie_perdue.connect(_maj_vies)
	joueur.mort.connect(_on_joueur_mort)
	joueur2.mort.connect(_on_joueur_mort)
	
	_maj_score(0)
	joueur.score_change.connect(_maj_score)

	call_deferred("_compter_ennemis")
	
	camera_partagee.joueur = joueur
	camera_partagee.joueur2 = joueur2

func _compter_ennemis() -> void:          # ← ICI, comme fonction du niveau
	ennemis_restants = get_tree().get_nodes_in_group("ennemi").size()
	
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

	vie_label_j2.visible = true
	_maj_vies_j2(joueur2.vies)
	joueur2.vie_perdue.connect(_maj_vies_j2)

	score_label_j2.visible = true
	_maj_score_j2(0)
	joueur2.score_change.connect(_maj_score_j2)
	
	camera_partagee.activer(true)

func _maj_vies(vies: int) -> void:
	vie_label.text = "J1 - Vies : %d" % vies

func _maj_vies_j2(vies: int) -> void:
	vie_label_j2.text = "J2 - Vies : %d" % vies
	
func _maj_score(score: int) -> void:
	score_label.text = "J1 - Score : %d" % score

func _maj_score_j2(score: int) -> void:
	score_label_j2.text = "J2 - Score : %d" % score

func _on_joueur_mort() -> void:
	if partie_terminee:
		return

	if not joueur2_actif:
		partie_terminee = true
		Resultat.vies_j1 = joueur.vies
		Resultat.multijoueur = false
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://game_over.tscn")
		return

	var j1_vivant : bool = joueur.vies > 0
	var j2_vivant : bool = joueur2.vies > 0

	if j1_vivant and not j2_vivant:
		_terminer_partie("J1")
	elif j2_vivant and not j1_vivant:
		_terminer_partie("J2")
	elif not j1_vivant and not j2_vivant:
		_terminer_partie("Egalite")
	

func _terminer_partie(vainqueur: String) -> void:
	partie_terminee = true

	Resultat.vies_j1 = joueur.vies
	Resultat.vies_j2 = joueur2.vies
	Resultat.multijoueur = true
	Resultat.vainqueur = vainqueur

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://victory.tscn")

func _on_ennemis_tues(qui: Node, nb: int) -> void:
	if qui and qui.has_method("ajouter_score"):
		qui.ajouter_score(nb * 100)

	ennemis_restants -= nb
	if ennemis_restants <= 0 and not partie_terminee:
		_victoire_ennemis_elimines()

func _victoire_ennemis_elimines() -> void:
	partie_terminee = true

	Resultat.vies_j1 = joueur.vies
	Resultat.vies_j2 = joueur2.vies
	Resultat.score_j1 = joueur.score
	Resultat.score_j2 = joueur2.score
	Resultat.multijoueur = joueur2_actif

	if joueur2_actif:
		if joueur.score > joueur2.score:
			Resultat.vainqueur = "J1"
		elif joueur2.score > joueur.score:
			Resultat.vainqueur = "J2"
		else:
			Resultat.vainqueur = "ScoreEgal"

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://victory.tscn")
	
