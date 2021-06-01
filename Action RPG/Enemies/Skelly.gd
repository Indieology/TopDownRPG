extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 90
export var MAX_SPEED = 30
export var FRICTION = 325
export var WANDER_TARGET_RANGE = 4
export var experience_pool = 50

enum {
	IDLE,
	WANDER,
	CHASE
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var player_position = Vector2.ZERO

var state = CHASE

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer
onready var player = get_parent().get_parent().get_parent().get_node("YSort/Player")

func _ready():
	state = pick_random_state([IDLE, WANDER])
	print(player)

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			sprite.play("Idle")
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
				
		WANDER:
			sprite.play("WalkDown")
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wanderController.target_position, delta)
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
			
		CHASE:
			var wr = weakref(player)
			if (!wr.get_ref()):
				 pass
			else:
				player_position = player.get_global_position()
				
			if abs(position.x-player_position.x)<abs(position.y-player_position.y):
				if position.y < player_position.y: 
					sprite.play("WalkDown")
					if (player_position - position).length() < 15:
						sprite.play("aDown")
						
				else: 
					sprite.play("WalkUp")
					if (player_position - position).length() < 15:
						sprite.play("aUp")
						
			if abs(position.x-player_position.x)>abs(position.y-player_position.y):
				if position.x < player_position.x:
					sprite.play("WalkRight")
					if (player_position - position).length() < 15:
						sprite.play("aRight")
						
				else:
					sprite.play("WalkLeft")
					if (player_position - position).length() < 15:
						sprite.play("aLeft")
						
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
				
			else:
				state = IDLE

	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= (area.damage + PlayerStats.strength)
	knockback = area.knockback_vector * 150
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func _on_Stats_no_health():
	PlayerStats.skeletons_killed += 1
	PlayerStats.OnKill(experience_pool)
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func _on_Hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	animationPlayer.play("Stop")