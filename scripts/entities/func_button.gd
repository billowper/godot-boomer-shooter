class_name FuncButton
extends Entity

var state:=false

func on_use() -> void:
    state = !state
