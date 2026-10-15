class_name Move
extends RefCounted

var from_sq: int
var to_sq: int
var promotion: PieceTypes.Type


func _init(p_from: int, p_to: int, p_promotion := PieceTypes.Type.NONE) -> void:
	from_sq = p_from
	to_sq = p_to
	promotion = p_promotion


func _to_string() -> String:
	return PieceTypes.square_name(from_sq) + PieceTypes.square_name(to_sq)
