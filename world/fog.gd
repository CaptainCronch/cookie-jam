extends Sprite2D
class_name Fog

@export var vision: GradientTexture2D
@export var resolution := Vector2i(2000, 2000)
@export var vision_size := Vector2i(64, 64)
@export var fog_scale := 100

var image: Image
var vision_image: Image


func _ready() -> void:
	Global.fog = self
	scale *= fog_scale
	vision.width = vision_size.x
	vision.height = vision_size.y
	image = Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBAH)
	image.fill(Color.BLACK)
	texture = ImageTexture.create_from_image(image)
	
	vision_image = vision.get_image()
	vision_image.convert(Image.FORMAT_RGBAH)


func update(vision_position: Vector2i) -> void:
	var vision_rect := Rect2(Vector2.ZERO, vision_image.get_size())
	#for building in get_tree().get_nodes_in_group("Vision"):
	@warning_ignore("integer_division")
	var pos := (vision_position / fog_scale) + (resolution/2) - (vision_image.get_size()/2)
	image.blend_rect(vision_image, vision_rect, pos)
	texture = ImageTexture.create_from_image(image)
