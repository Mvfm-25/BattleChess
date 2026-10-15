extends SceneTree
## Carrega a cena principal, simula cliques e2 -> e4 e verifica o estado.
## Rodar: godot --headless --path . --script res://tests/smoke_test.gd


func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var game: GameManager = main.get_node("GameManager")
	var view: BoardView = main.get_node("BoardView")
	var e2 := PieceTypes.square(4, 1)
	var e4 := PieceTypes.square(4, 3)

	var ok := view.world_to_square(view.square_to_world(e2)) == e2
	view.square_clicked.emit(e2)
	view.square_clicked.emit(e4)
	for i in 30:
		await process_frame

	ok = ok and game.board.piece_at(e4) == PieceTypes.make(PieceTypes.Type.PAWN, PieceTypes.Side.WHITE)
	ok = ok and game.board.piece_at(e2) == PieceTypes.EMPTY
	ok = ok and view.get_node("Pieces").get_child_count() == 32
	print("status: ", game.status_text)
	print("smoke test ", "OK" if ok else "FALHOU")
	quit(0 if ok else 1)
