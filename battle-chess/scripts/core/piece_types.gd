class_name PieceTypes
extends RefCounted
## Codificação das peças e das casas, compartilhada pela lógica e pela apresentação.
## Peça = tipo (1..6) | BLACK_FLAG se for preta. 0 = casa vazia.
## Casa = rank * 8 + file, com a1 = 0 e h8 = 63.

enum Type { NONE, PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Side { WHITE, BLACK }

const EMPTY := 0
const BLACK_FLAG := 8


static func make(type: PieceTypes.Type, side: PieceTypes.Side) -> int:
	return type | (BLACK_FLAG if side == PieceTypes.Side.BLACK else 0)


static func type_of(piece: int) -> PieceTypes.Type:
	return (piece & 7) as PieceTypes.Type


static func side_of(piece: int) -> PieceTypes.Side:
	return PieceTypes.Side.BLACK if piece & BLACK_FLAG else PieceTypes.Side.WHITE


static func opponent(side: PieceTypes.Side) -> PieceTypes.Side:
	return PieceTypes.Side.BLACK if side == PieceTypes.Side.WHITE else PieceTypes.Side.WHITE


static func square(file: int, rank: int) -> int:
	return rank * 8 + file


static func file_of(sq: int) -> int:
	return sq & 7


static func rank_of(sq: int) -> int:
	return sq >> 3


static func square_name(sq: int) -> String:
	return "abcdefgh"[file_of(sq)] + str(rank_of(sq) + 1)


static func side_name(side: PieceTypes.Side) -> String:
	return "Brancas" if side == PieceTypes.Side.WHITE else "Pretas"
