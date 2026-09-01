extends RefCounted
class_name GameModeState

enum Mode { SURVIVAL, CREATIVE }

var current: Mode = Mode.SURVIVAL

func toggle() -> void:
	current = Mode.CREATIVE if current == Mode.SURVIVAL else Mode.SURVIVAL

func display_name() -> String:
	return "Criativo" if current == Mode.CREATIVE else "Sobrevivência"

func can_place_without_resource() -> bool:
	return current == Mode.CREATIVE
