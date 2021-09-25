extends MenuButton

var dino_scenes = [
	preload("res://Dinos/Dino.tscn"),
	preload("res://Dinos/Stego.tscn"),
	preload("res://Dinos/Tric.tscn"),
	preload("res://Dinos/Trex.tscn"),
	preload("res://Dinos/Bracio.tscn"),
]

func _ready():
	var pop = get_popup()
	pop.connect("id_pressed", self, "_on_item_pressed")

func _on_item_pressed(ID):
	var ysort := $"../YSort Dinos"
	var dino_scene: PackedScene = dino_scenes[ID]
	var dino = dino_scene.instance()
	dino.position = Vector2(250, 250)
	ysort.add_child(dino)
