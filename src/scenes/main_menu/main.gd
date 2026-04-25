extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	title_label.text = "Sangoku Mahjong"
	status_label.text = "Phase 0 scaffold ready"
