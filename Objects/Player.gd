extends CharacterBody3D

@export var is_controlling: bool = false
@export var hp_label: Label

const HALF_PI: float = PI / 2.0
const SPEED: float = 500.0
const JUMP_VELOCITY: float = 4.5
const PLAYER_ROTATION_SPEED: float = 0.5
const CAMERA_TILT_SPEED: float = 0.5

var mouse_relative: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var speed: float = 0.0
var hp: int = 3

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var player_camera: Camera3D = $PlayerCamera
@onready var gun_anim_tree: AnimationTree = %GunAnimTree
@onready var gun_animation: AnimationPlayer = %GunAnimation
@onready var ray: RayCast3D = %Ray
@onready var rigid_player_resource: Resource = preload("res://Objects/RigidPlayer.tscn")

func _ready() -> void:
	if is_controlling:
		player_camera.make_current()
		update_hp(true)
	else:
		player_camera.attributes = null
		player_camera.clear_current()

func _input(event: InputEvent) -> void:
	if is_controlling and event is InputEventMouseMotion:
		mouse_relative = event.relative

func _process(_delta: float) -> void:
	if is_controlling:
		input_dir = Input.get_vector("left", "right", "up", "down")
		if input_dir:
			gun_anim_tree.set("parameters/conditions/idle", false)
			gun_anim_tree.set("parameters/conditions/moving", true)
		else:
			gun_anim_tree.set("parameters/conditions/moving", false)
			gun_anim_tree.set("parameters/conditions/idle", true)

		if Input.is_action_pressed("aim"):
			gun_anim_tree.set("parameters/conditions/idle", false)
			gun_anim_tree.set("parameters/conditions/moving", false)
			gun_anim_tree.set("parameters/conditions/aiming", true)
			speed = SPEED / 3.0
		else:
			gun_anim_tree.set("parameters/conditions/aiming", false)
			speed = SPEED

		if Input.is_action_just_pressed("shoot"):
			gun_anim_tree.set("parameters/conditions/shoot", true)
			gun_animation.seek(0, true)

			var collider: Object = ray.get_collider()
			if collider is CharacterBody3D and collider.update_hp():
				var rigid_player: RigidBody3D = rigid_player_resource.instantiate()
				rigid_player.position = collider.position
				rigid_player.rotation = collider.rotation
				var force: Vector3 = (collider.position - position).normalized() * 400
				var y_pos: float = ray.get_collision_point().y - collider.position.y - 1.0
				rigid_player.apply_force(force, Vector3(0.0, y_pos, 0.0))
				get_parent_node_3d().add_child(rigid_player)
				collider.queue_free()
		else:
			gun_anim_tree.set("parameters/conditions/shoot", false)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_controlling:
		if mouse_relative:
			var player_rotation_speed: float = PLAYER_ROTATION_SPEED
			var camera_tilt_speed: float = CAMERA_TILT_SPEED

			if gun_anim_tree.get("parameters/conditions/aiming"):
				player_rotation_speed *= 0.25
				camera_tilt_speed *= 0.25

			rotation.y -= mouse_relative.x * player_rotation_speed * delta
			player_camera.rotation.x -= mouse_relative.y * camera_tilt_speed * delta
			player_camera.rotation.x = clampf(player_camera.rotation.x, -HALF_PI, HALF_PI)
			mouse_relative = Vector2.ZERO

		if Input.is_action_just_pressed("jump") and is_on_floor() and not gun_anim_tree.get("parameters/conditions/aiming"):
			velocity.y = JUMP_VELOCITY

		var move_speed: float = speed * delta
		if input_dir:
			var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

func update_hp(only_set: bool = false) -> bool:
	var result: bool = false

	if not only_set:
		hp -= 1
		if hp <= 0:
			result = true

	if is_controlling:
		hp_label.text = "HP: %d" % hp

	return result
