extends SceneTree
## Conta os nós da árvore de lances (perft) e compara com valores conhecidos.
## Até profundidade 3 não há roque/en passant possível, então os valores oficiais valem.
## Rodar: godot --headless --path . --script res://tests/perft_test.gd

const EXPECTED := [1, 20, 400, 8902]


func _init() -> void:
	var board := ChessBoard.new()
	board.setup_initial()
	var ok := true
	for depth in range(1, EXPECTED.size()):
		var nodes := perft(board, depth)
		var passed: bool = nodes == EXPECTED[depth]
		ok = ok and passed
		print("perft(%d) = %d (esperado %d) %s" % [depth, nodes, EXPECTED[depth], "OK" if passed else "FALHOU"])
	quit(0 if ok else 1)


func perft(board: ChessBoard, depth: int) -> int:
	if depth == 0:
		return 1
	var total := 0
	for move in MoveGenerator.legal_moves(board):
		var next := board.duplicate_board()
		next.make_move(move)
		total += perft(next, depth - 1)
	return total
