class_name HealthComponent
extends Node
## Hit points shared by the player and enemies (1 point = half a heart for the player).

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal died

@export var max_health := 10

var health := 0
var is_dead: bool:
	get:
		return health <= 0


func _ready() -> void:
	health = max_health


func apply_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	health = maxi(health - amount, 0)
	damaged.emit(amount)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()


func heal(amount: int) -> void:
	if is_dead:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func reset() -> void:
	health = max_health
	health_changed.emit(health, max_health)
