extends CanvasLayer

@export var game: GameManager

@onready var _status: Label = %StatusLabel
@onready var _new_game: Button = %NewGameButton


func _ready() -> void:
	game.status_changed.connect(_status.set_text)
	_new_game.pressed.connect(game.new_game)
	_status.text = game.status_text
