extends Control

@onready var titre: Label = $Label
@onready var bouton_rejouer: Button = $BoutonRejouer

func _ready() -> void:
	bouton_rejouer.pressed.connect(_on_rejouer_pressed)
	bouton_rejouer.grab_focus()
	_animer_titre()

func _animer_titre() -> void:
	titre.pivot_offset = titre.size / 2
	titre.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(titre, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_rejouer_pressed() -> void:
	get_tree().change_scene_to_file("res://bomberman.tscn")
