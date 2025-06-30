extends Node

var player_name : String
var player_list = []

var time : float = 0

func _ready() -> void:
	SilentWolf.configure({
		"api_key": "Dkbu6eMJBD4T568KqSbyoaXq6bYs1Fxq5jDViboq",
		"game_id": "",
		"log_level": 1
	})


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
