extends Control

# --- EXPORT VARIABLES ---
# You can change these values in the Godot Inspector.

# How fast the text appears, in characters per second.
@export var typing_speed: float = 25.0

# The total number of slides you have in your scene.
# Make sure this matches the count of your Label nodes (slide1, slide2, etc.).
@export var total_slides: int = 1

# --- NODES ---
# Make sure you have an AudioStreamPlayer node named "dialogue" as a child.
@onready var dialogue_sounds : AudioStreamPlayer = $dialogue

# --- PRIVATE VARIABLES ---
# These are used by the script to track its state.

# Keeps track of which slide is currently visible.
var _current_slide_index: int = 1

# A flag to check if the text is currently being "typed out".
# This prevents skipping to the next slide before the current one finishes.
var _is_typing: bool = false

# Tracks the number of characters that have had a sound played for them.
var _characters_played_sound_for: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure the process mode is always active so input is detected.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start the intro sequence with the first slide.
	_start_slide(_current_slide_index)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If we aren't typing, there's nothing to do in the process loop.
	if not _is_typing:
		return

	# Get a reference to the current slide Label.
	var current_slide_label: Label = get_node("slide" + str(_current_slide_index))
	var text_length: int = current_slide_label.text.length()

	# Avoid division by zero if a label is empty.
	if text_length > 0:
		# Calculate the increment based on characters per second.
		# This makes the "typing" feel consistent regardless of text length.
		var ratio_increment = (typing_speed / float(text_length)) * delta
		current_slide_label.visible_ratio += ratio_increment
		
		# --- SOUND LOGIC ---
		# Calculate how many characters should be visible based on the current ratio.
		var currently_visible_chars = floor(current_slide_label.visible_ratio * text_length)

		# Use a while loop to ensure a sound plays for every new character,
		# even if the framerate is low and multiple characters appear at once.
		while _characters_played_sound_for < currently_visible_chars:
			# Get the character that was just revealed.
			var new_char = current_slide_label.text[_characters_played_sound_for]
			# Only play a sound if the character is not a space.
			if new_char != " ":
				dialogue_sounds.play()
			
			# Increment the counter for the character we just processed.
			_characters_played_sound_for += 1
	else:
		# If the label is empty, just finish it immediately.
		current_slide_label.visible_ratio = 1.0

	# Once the ratio is 1 or more, the text is fully visible.
	if current_slide_label.visible_ratio >= 1.0:
		# Clamp the value to exactly 1.0 to ensure it's finished.
		current_slide_label.visible_ratio = 1.0
		# Set the flag to false, allowing the player to proceed.
		_is_typing = false


# Called when any input is detected that hasn't been handled by the GUI.
func _input(event: InputEvent) -> void:
	# We only want to proceed if the typing is finished.
	if _is_typing:
		return

	# Check for specific inputs to advance the slide.
	# "ui_accept" usually covers Enter, Space, and gamepad confirm buttons.
	# We also check for a screen touch on mobile devices.
	if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.is_pressed()):
		# Mark the event as handled so it doesn't trigger other actions.
		get_viewport().set_input_as_handled()
		_go_to_next_slide()
	if OS.is_debug_build() and Input.is_action_just_pressed("debug"):
		_current_slide_index = 9
		_go_to_next_slide()

# --- HELPER FUNCTIONS ---

# Handles the logic for advancing the slides or loading the main game.
func _go_to_next_slide() -> void:
	_current_slide_index += 1

	# Check if we have gone past the last slide.
	if _current_slide_index > total_slides:
		# All slides are done, so show the container and hide the slide.
		$CenterContainer.show()
		$slide1.hide()
	else:
		# There's another slide, so set it up.
		_start_slide(_current_slide_index)


# Prepares and starts the animation for a specific slide.
func _start_slide(slide_number: int) -> void:
	# Loop through all possible slides to hide them first.
	for i in range(1, total_slides + 1):
		var slide_node: Label = get_node_or_null("slide" + str(i))
		if slide_node:
			slide_node.visible = false

	# Get the specific slide we want to show.
	var target_slide: Label = get_node_or_null("slide" + str(slide_number))

	# If the slide exists, make it visible and start the typing.
	if target_slide:
		target_slide.visible = true
		target_slide.visible_ratio = 0.0 # Reset the typing effect.
		_is_typing = true
		_characters_played_sound_for = 0 # Reset the sound counter for the new slide.
	else:
		# This is a safeguard in case a slide node is missing.
		print("Error: Could not find Label node named 'slide" + str(slide_number) + "'")
		_is_typing = false


func _on_button_pressed() -> void:
	_current_slide_index = 9
	_go_to_next_slide()
