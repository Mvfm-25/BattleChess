class_name MoveGenerator
extends RefCounted
## Geração de lances legais.
## Protótipo: sem roque e sem en passant; promoção é sempre para dama.

const KNIGHT_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
	Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2),
]
const KING_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
]
const ROOK_DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const BISHOP_DIRS: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]


static func legal_moves(board: ChessBoard) -> Array[Move]:
	var result: Array[Move] = []
	for move in pseudo_legal_moves(board, board.side_to_move):
		if not _leaves_king_in_check(board, move):
			result.append(move)
	return result


static func legal_moves_from(board: ChessBoard, sq: int) -> Array[Move]:
	var result: Array[Move] = []
	var piece := board.piece_at(sq)
	if piece == PieceTypes.EMPTY or PieceTypes.side_of(piece) != board.side_to_move:
		return result
	for move in _piece_moves(board, sq):
		if not _leaves_king_in_check(board, move):
			result.append(move)
	return result


static func is_in_check(board: ChessBoard, side: PieceTypes.Side) -> bool:
	var king_sq := board.find_king(side)
	return king_sq != -1 and is_square_attacked(board, king_sq, PieceTypes.opponent(side))


## Só vale para casas ocupadas (peão não "ataca" para frente, mas isso basta para checar o rei).
static func is_square_attacked(board: ChessBoard, sq: int, by_side: PieceTypes.Side) -> bool:
	for move in pseudo_legal_moves(board, by_side):
		if move.to_sq == sq:
			return true
	return false


static func pseudo_legal_moves(board: ChessBoard, side: PieceTypes.Side) -> Array[Move]:
	var result: Array[Move] = []
	for sq in 64:
		var piece := board.piece_at(sq)
		if piece != PieceTypes.EMPTY and PieceTypes.side_of(piece) == side:
			result.append_array(_piece_moves(board, sq))
	return result


static func _leaves_king_in_check(board: ChessBoard, move: Move) -> bool:
	var side := PieceTypes.side_of(board.piece_at(move.from_sq))
	var after := board.duplicate_board()
	after.make_move(move)
	return is_in_check(after, side)


static func _piece_moves(board: ChessBoard, sq: int) -> Array[Move]:
	match PieceTypes.type_of(board.piece_at(sq)):
		PieceTypes.Type.PAWN:
			return _pawn_moves(board, sq)
		PieceTypes.Type.KNIGHT:
			return _step_moves(board, sq, KNIGHT_OFFSETS)
		PieceTypes.Type.KING:
			return _step_moves(board, sq, KING_OFFSETS)
		PieceTypes.Type.BISHOP:
			return _slide_moves(board, sq, BISHOP_DIRS)
		PieceTypes.Type.ROOK:
			return _slide_moves(board, sq, ROOK_DIRS)
		PieceTypes.Type.QUEEN:
			return _slide_moves(board, sq, ROOK_DIRS + BISHOP_DIRS)
	var none: Array[Move] = []
	return none


## Casa deslocada por d, ou -1 se sair do tabuleiro.
static func _offset(sq: int, d: Vector2i) -> int:
	var file := PieceTypes.file_of(sq) + d.x
	var rank := PieceTypes.rank_of(sq) + d.y
	if file < 0 or file > 7 or rank < 0 or rank > 7:
		return -1
	return PieceTypes.square(file, rank)


static func _step_moves(board: ChessBoard, sq: int, offsets: Array) -> Array[Move]:
	var result: Array[Move] = []
	var side := PieceTypes.side_of(board.piece_at(sq))
	for d: Vector2i in offsets:
		var target := _offset(sq, d)
		if target == -1:
			continue
		var occupant := board.piece_at(target)
		if occupant == PieceTypes.EMPTY or PieceTypes.side_of(occupant) != side:
			result.append(Move.new(sq, target))
	return result


static func _slide_moves(board: ChessBoard, sq: int, dirs: Array) -> Array[Move]:
	var result: Array[Move] = []
	var side := PieceTypes.side_of(board.piece_at(sq))
	for d: Vector2i in dirs:
		var target := _offset(sq, d)
		while target != -1:
			var occupant := board.piece_at(target)
			if occupant == PieceTypes.EMPTY:
				result.append(Move.new(sq, target))
			else:
				if PieceTypes.side_of(occupant) != side:
					result.append(Move.new(sq, target))
				break
			target = _offset(target, d)
	return result


static func _pawn_moves(board: ChessBoard, sq: int) -> Array[Move]:
	var result: Array[Move] = []
	var side := PieceTypes.side_of(board.piece_at(sq))
	var dir := 1 if side == PieceTypes.Side.WHITE else -1
	var start_rank := 1 if side == PieceTypes.Side.WHITE else 6

	var one := _offset(sq, Vector2i(0, dir))
	if one != -1 and board.piece_at(one) == PieceTypes.EMPTY:
		_add_pawn_move(result, sq, one)
		var two := _offset(sq, Vector2i(0, 2 * dir))
		if PieceTypes.rank_of(sq) == start_rank and board.piece_at(two) == PieceTypes.EMPTY:
			result.append(Move.new(sq, two))

	for dx in [-1, 1]:
		var target := _offset(sq, Vector2i(dx, dir))
		if target == -1:
			continue
		var occupant := board.piece_at(target)
		if occupant != PieceTypes.EMPTY and PieceTypes.side_of(occupant) != side:
			_add_pawn_move(result, sq, target)
	return result


static func _add_pawn_move(result: Array[Move], from_sq: int, to_sq: int) -> void:
	var rank := PieceTypes.rank_of(to_sq)
	if rank == 0 or rank == 7:
		result.append(Move.new(from_sq, to_sq, PieceTypes.Type.QUEEN))
	else:
		result.append(Move.new(from_sq, to_sq))
