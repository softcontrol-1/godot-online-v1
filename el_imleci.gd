extends Sprite2D

# Resimleri hafızaya yükleyelim (Adları seninkilerle aynı olmalı!)
var normal_resim = preload("res://Assets/Sprites/el_normal.png")
var tikla_resim = preload("res://Assets/Sprites/el_tikla.png")

func _ready():
	# Oyun başladığında gerçek fareyi GİZLE
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	# 1. HAREKET: Eli, gerçek farenin olduğu konuma ışınla
	global_position = get_global_mouse_position()
	
	# 2. ANİMASYON: Sol tık basılı mı?
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		texture = tikla_resim # Basılıysa ezilmiş eli göster
	else:
		texture = normal_resim # Değilse normal eli göster
