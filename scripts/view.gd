extends Node3D

@export_group("Properties")
@export var target: Vehicle

# --- Rear-bumper chase camera settings ---
@export_group("Chase Camera")
@export var offset_behind: float = 6.0   # Distance behind the car (metres)
@export var offset_up: float    = 2.0   # Height above the car
@export var position_lag: float = 6.0   # How quickly position catches up  (higher = tighter)
@export var rotation_lag: float = 5.0   # How quickly rotation catches up

@onready var camera = $Camera

# Functions

func _physics_process(delta):

	# ── 1. Compute the world-space desired camera position ──────────────────
	# vehicle_model.global_basis.z  points FORWARD in Godot's right-hand system;
	# we negate it to get the REAR direction, then push the camera back & up.

	var car_basis  : Basis   = target.vehicle_model.global_basis
	var car_pos    : Vector3 = target.get_vehicle_position()

	var rear_dir   : Vector3 = -car_basis.z            # unit vector pointing behind
	var desired_pos: Vector3 = car_pos \
		+ rear_dir  * offset_behind \
		+ car_basis.y * offset_up

	# ── 2. Smoothly follow position (lag gives cinematic feel) ──────────────
	self.global_position = self.global_position.lerp(desired_pos, delta * position_lag)

	# ── 3. Smoothly rotate to look at the car ───────────────────────────────
	var look_target: Vector3 = car_pos + car_basis.y * (offset_up * 0.4)  # look slightly above centre
	var target_transform: Transform3D = self.global_transform.looking_at(look_target, car_basis.y)
	self.global_transform = self.global_transform.interpolate_with(target_transform, delta * rotation_lag).orthonormalized()

	# ── 4. Dynamic zoom on the local camera node (speed-based FOV feel) ─────
	var speed_factor: float = clamp(abs(target.linear_speed), 0.0, 1.0)
	var target_z: float     = remap(speed_factor, 0.0, 1.0, 0.0, -2.0)  # subtle push-in at speed
	camera.position.z = lerp(camera.position.z, target_z, delta * 0.5)
