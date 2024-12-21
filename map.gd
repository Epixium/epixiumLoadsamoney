extends Node2D

class_name Level

@onready var player_scene = preload("res://Player/Scenes/player.tscn")

@export var spawnPoint : Marker2D
@export var tileSetMain : TileMapLayer
@export var tileSetBreakable : TileMapLayer

func _ready():
	GameState.collectibles = 0
	GameState.breakTileSet = tileSetBreakable
	GameState.tileSet = tileSetMain
	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = spawnPoint.global_position
