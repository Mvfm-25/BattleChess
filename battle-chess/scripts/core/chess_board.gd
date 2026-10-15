class_name ChessBoard
extends RefCounted
## Estado puro do tabuleiro: nenhuma dependência de nodos.

const BACK_RANK: Array[PieceTypes.Type] = [
	PieceTypes.Type.ROOK, PieceTypes.Type.KNIGHT, PieceTypes.Type.BISHOP, PieceTypes.Type.QUEEN,
	PieceTypes.Type.KING, PieceTypes.Type.BISHOP, PieceTypes.Type.KNIGHT, PieceTypes.Type.ROOK,
]

var squares := PackedInt32Array()
var side_to_move := PieceTypes.Side.WHITE


func _init() -> void:
	squares.resize(64)


func setup_initial() -> void:
	squares.fill(PieceTypes.EMPTY)
	for file in 8:
		squares[PieceTypes.square(file, 0)] = PieceTypes.make(BACK_RANK[file], PieceTypes.Side.WHITE)
		squares[PieceTypes.square(file, 1)] = PieceTypes.make(PieceTypes.Type.PAWN, PieceTypes.Side.WHITE)
		squares[PieceTypes.square(file, 6)] = PieceTypes.make(PieceTypes.Type.PAWN, PieceTypes.Side.BLACK)
		squares[PieceTypes.square(file, 7)] = PieceTypes.make(BACK_RANK[file], PieceTypes.Side.BLACK)
	side_to_move = PieceTypes.Side.WHITE


func piece_at(sq: int) -> int:
	return squares[sq]


func duplicate_board() -> ChessBoard:
	var copy := ChessBoard.new()
	copy.squares = squares.duplicate()
	copy.side_to_move = side_to_move
	return copy


## Aplica o lance sem validar. Retorna a peça capturada (ou EMPTY).
func make_move(move: Move) -> int:
	var captured := squares[move.to_sq]
	var piece := squares[move.from_sq]
	if move.promotion != PieceTypes.Type.NONE:
		piece = PieceTypes.make(move.promotion, PieceTypes.side_of(piece))
	squares[move.to_sq] = piece
	squares[move.from_sq] = PieceTypes.EMPTY
	side_to_move = PieceTypes.opponent(side_to_move)
	return captured


func find_king(side: PieceTypes.Side) -> int:
	return squares.find(PieceTypes.make(PieceTypes.Type.KING, side))
