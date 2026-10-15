class_name GameManager
extends Node
## Liga a lógica (ChessBoard/MoveGenerator) à apresentação (BoardView).

signal status_changed(text: String)

@export var board_view: BoardView

var board := ChessBoard.new()
var status_text := ""

var _selected := -1
var _selected_moves: Array[Move] = []
var _game_over := false


func _ready() -> void:
	board_view.square_clicked.connect(_on_square_clicked)
	new_game()


func new_game() -> void:
	board.setup_initial()
	_game_over = false
	_clear_selection()
	board_view.show_board(board)
	_update_status()


func _on_square_clicked(sq: int) -> void:
	if _game_over:
		return
	for move in _selected_moves:
		if move.to_sq == sq:
			_play(move)
			return

	var piece := board.piece_at(sq)
	if sq != _selected and piece != PieceTypes.EMPTY and PieceTypes.side_of(piece) == board.side_to_move:
		_selected = sq
		_selected_moves = MoveGenerator.legal_moves_from(board, sq)
		board_view.show_selection(sq, _selected_moves)
	else:
		_clear_selection()


func _play(move: Move) -> void:
	board.make_move(move)
	_clear_selection()
	board_view.apply_move(move)
	_update_status()


func _clear_selection() -> void:
	_selected = -1
	_selected_moves.clear()
	board_view.clear_highlights()


func _update_status() -> void:
	var side := board.side_to_move
	var in_check := MoveGenerator.is_in_check(board, side)
	if MoveGenerator.legal_moves(board).is_empty():
		_game_over = true
		if in_check:
			status_text = "Xeque-mate! %s vencem." % PieceTypes.side_name(PieceTypes.opponent(side))
		else:
			status_text = "Afogamento: empate."
	elif in_check:
		status_text = "Vez das %s: xeque!" % PieceTypes.side_name(side)
	else:
		status_text = "Vez das %s" % PieceTypes.side_name(side)
	status_changed.emit(status_text)
