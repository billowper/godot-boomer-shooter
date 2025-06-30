class_name Entity
extends Node3D

signal used()

func use() -> void:
    on_use()
    used.emit()

func on_use() -> void:
    pass;