extends Node

@onready var mana_cost: float = 10.0
@onready var max_mana: float = 100.0
@export var current_mana: float = 100.0
@export var mana_regeneration: float = 2.5
@onready var mana_bar = %ManaBar

func update_mana_bar() -> void:
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

func _ready() -> void:
	update_mana_bar()

func _process(delta: float) -> void:
	if current_mana < max_mana:
		current_mana += mana_regeneration * delta
		current_mana = min(current_mana, max_mana)
