extends Node

# Artifact database singleton
# Loads and manages artifact data from JSON

var artifacts: Dictionary = {}

func _ready():
	load_artifacts_from_json()

func load_artifacts_from_json():
	var file = FileAccess.open("res://data/artifacts.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			artifacts = json.data
			print("Loaded ", artifacts.size(), " artifacts")
		else:
			print("Error parsing artifacts.json: ", json.get_error_message())
	else:
		print("Could not open artifacts.json")

func get_artifact(artifact_id: String) -> Dictionary:
	return artifacts.get(artifact_id, {})

func get_icon(artifact_id: String) -> Texture2D:
	var artifact = get_artifact(artifact_id)

	# Try to load icon file if it exists
	if artifact.has("icon"):
		var path = "res://art/icons/" + artifact["icon"]
		if ResourceLoader.exists(path):
			var resource = ResourceLoader.load(path)
			if resource != null:
				return resource
			else:
				print("Warning: Failed to load icon resource: ", path)

	# Return category-colored placeholder if icon not found
	var category = artifact.get("category", "")
	return _get_placeholder_icon(category)

func _get_placeholder_icon(category: String = "") -> Texture2D:
	var color = Color(0.4, 0.4, 0.4)  # Default gray

	# Color mapping based on category
	match category:
		"loop":
			color = Color.BLUE
		"shield":
			color = Color.GRAY
		"armor":
			color = Color.SADDLE_BROWN
		"weapon":
			color = Color.RED
		"magic":
			color = Color.PURPLE
		"consumable":
			color = Color.GREEN

	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex = ImageTexture.create_from_image(img)
	return tex

func artifact_exists(artifact_id: String) -> bool:
	return artifacts.has(artifact_id)

func get_all_artifacts() -> Dictionary:
	return artifacts
