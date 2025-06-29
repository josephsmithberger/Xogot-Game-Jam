extends Node

var elapsed_time: float = 0.0
@onready var label: Label = $Control/CenterContainer/Label
@onready var finished_screen: Control = $finished_level
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer

# Preload the music once
var sewer_city_music = preload("res://game/SewerCity.ogg")
var reflections_music = preload("res://game/StaringAtReflections.ogg")

var counting: bool = true
var current_stream: AudioStream = null

func _ready() -> void:
	elapsed_time = 0.0
	finished_screen.visible = false
	_set_music(reflections_music)

func _process(delta: float) -> void:
	if counting:
		elapsed_time += delta
		label.text = "Time: %.2f" % elapsed_time

	# Only switch if needed
	if $finished_level.visible and current_stream != sewer_city_music:
		_set_music(sewer_city_music)
	elif not $finished_level.visible and current_stream != reflections_music:
		_set_music(reflections_music)

func _on_finished_level_next_level() -> void:
	elapsed_time = 0.0

func _on_node_3d_new_level() -> void:
	counting = false
	finished_screen.finished_level("%.2f" % elapsed_time)
	finished_screen.visible = true

func _set_music(stream: AudioStream) -> void:
	current_stream = stream

	if stream is AudioStreamOggVorbis:
		var ogg_stream := stream as AudioStreamOggVorbis
		ogg_stream.loop = true  # Needed for loop points to be used

	music_player.stream = stream
	music_player.play()
