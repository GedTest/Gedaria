class_name Vladimir, "res://Vladimir/animations/Vladimir.png"
extends KinematicBody2D
"""
Main character
"""


const GRAVITY = Vector2(0, 98)
const FLOOR_NORMAL = Vector2(0, -1)
const PEBBLE_PATH = preload("res://Vladimir/Pebble.tscn")

export(int) var speed = 480
export(int) var modify_speed = 1
export(int) var jump_strength = 1700
export(int) var damage = 2
export(int) var max_health = 12
export(int) var health = 12

var shoot_distance = 500
var acorn_counter = 0
var pebble_counter = 0
var heavy_attack_counter = 0
var jump_forgivness_timer = 0.0
var next_pos_ID = ""

var direction = 1
var attack_direction = 1
var velocity = Vector2(0, 0)
var mouse_position = Vector2(0, 0)
var jumped_height = Vector2(0, 0)

var is_dead = false
var is_moving = true
var can_move = true
var can_jump = true
var is_crouching = false
var can_attack = false
var is_attacking = false
var is_blocking = false
var is_hidden = false
var is_aimining = false
var is_hitted = false
var is_raking = false
var is_yield_paused = false
var has_slingshot = false

var has_learned_attack = true
var has_learned_heavy_attack = true
var has_learned_raking = true
var has_learned_blocking = true

var enemy = null
var attack_timer = null
var heavy_attack_timer = null
var block_timer = null
var state_machine = null

#var t = 0.0


func _ready():
	set_collision_layer_bit(1, true)
	state_machine = $AnimationTree.get("parameters/playback")
	attack_timer = get_tree().create_timer(0.0)
	heavy_attack_timer = get_tree().create_timer(0.0)
	block_timer = get_tree().create_timer(0.0)
# ------------------------------------------------------------------------------	

# warning-ignore:unused_argument
func _physics_process(delta):
	if !is_dead:
		is_yield_paused = get_parent().is_yield_paused
		update() # Draw function
		
	# GRAVITY
		velocity.y += GRAVITY.y
		
	# IS HE ALIVE ?
		if health <= 0:
			die()
			
	# IF HE'S NOT STOP BY SOME EVENT
		if is_moving:
			jump(delta)
			move()
			crouch()
			attack()
			heavy_attack(delta)
			shoot()
			block()
			rake()
		
			# I don't like this method, it already multiply by delta
			velocity = move_and_slide(velocity, FLOOR_NORMAL, \
									  false, 4, PI,false)
# ------------------------------------------------------------------------------

func jump(delta): # JUMP
	var MAX_TIME = 0.1
	
	can_jump = true if ($GroundRay.is_colliding() or
						$GroundRay2.is_colliding() or
						$GroundRay3.is_colliding()
						)else false
	if can_jump:
		jump_forgivness_timer = 0.0
	else:
		jump_forgivness_timer += delta
		if jump_forgivness_timer <= MAX_TIME:
			can_jump = true
						
	if Input.is_action_just_pressed("jump") and can_jump:
		jumped_height.y = position.y
		velocity.y = -jump_strength
# ------------------------------------------------------------------------------

func move(): # MOVE
	if Input.is_action_pressed("right") and !is_raking:
		direction = 1
		attack_direction = 1
		$Sprite.flip_h = false
		$WeaponHitbox.position.x = 90
	elif Input.is_action_pressed("left") and !is_raking:
		direction = -1
		attack_direction = -1
		$Sprite.flip_h = true
		$WeaponHitbox.position.x = -90
	else:
		direction = 0
	
	velocity.x = direction * (speed*modify_speed) * int(can_move) # * delta
	var animation = "RUN" if velocity.x != 0  else "IDLE"
	
	
	$Sprite.flip_v = false
	if !is_hitted and !is_attacking and !is_raking and !is_dead and !is_aimining:
		state_machine.travel(animation)
# ------------------------------------------------------------------------------

func crouch(): # CROUCH
	var bCanStandUp = false if $CeilingRay.is_colliding() else true
	
	if (Input.is_action_pressed("crouch") and !is_hitted) or !bCanStandUp:
		is_crouching = true
		$CollisionShape2D.position.y = 35
		$CollisionShape2D.scale.y = 0.825
		state_machine.travel('CRAWLING')
		velocity.x = direction * speed / 1.6
		
	else:
		is_crouching = false
		$CollisionShape2D.position.y = 22
		$CollisionShape2D.scale.y = 1
# ------------------------------------------------------------------------------

func attack(): # LIGHT ATTACK, fast but low dmg,
	if has_learned_attack:
		if Input.is_action_just_pressed("attack") and !is_attacking and !is_blocking:
			is_attacking = true
#			can_move = false
			$AnimationTree.set("parameters/ATTACK/blend_position", attack_direction)
			if state_machine.get_current_node() != "HOLD_PEBBLE":
				state_machine.travel('ATTACK')
			
			if attack_timer.time_left <= 0.0:
				attack_timer = get_tree().create_timer(0.35)
				if !is_yield_paused:
					yield(attack_timer, "timeout")
					if enemy and can_attack:
						enemy.hit(damage)
					
					can_move = true
					is_attacking = false
# ------------------------------------------------------------------------------

func heavy_attack(delta): # HEAVY ATTACK, slow but high dmg
	if has_learned_heavy_attack and heavy_attack_counter > 0:
		var current_animation = state_machine.get_current_node()
		
		
#		if Input.is_action_pressed("attack"):
#			t += delta
#		if Input.is_action_just_pressed("attack"):
#			t = 0
#		if Input.is_action_just_released("attack"):
#			t = 0
#		if t >= 0.3 and Input.is_action_pressed("attack") and !is_attacking and !is_blocking:
#			t = -999
#			print('yay HOLD')#hfl
		
		
		if Input.is_action_just_pressed("heavy attack") and !is_attacking and !is_blocking:
			if current_animation != 'HEAVY_ATTACK':
				$AnimationTree.set("parameters/HEAVY_ATTACK/blend_position", attack_direction)
				state_machine.travel('HEAVY_ATTACK')
				heavy_attack_counter -= 1
				
				if heavy_attack_timer.time_left <= 0.0:
					heavy_attack_timer = get_tree().create_timer(1.25)
					if !is_yield_paused:
						yield(heavy_attack_timer, "timeout")
						
						if enemy and can_attack:
							enemy.is_heavy_attacked = true
							enemy.hit(damage)
							enemy.jump_back()

#						t = 0
# ------------------------------------------------------------------------------

func shoot():
	if Input.is_action_pressed("shoot") and pebble_counter > 0 and !is_crouching:
		can_move = false
		is_aimining = true
		mouse_position = get_local_mouse_position()
		var animation = "SLINGSHOT" if has_slingshot else "PEBBLE"
		state_machine.travel("HOLD_" + animation)
		
		if Input.is_action_just_pressed("attack"):
			state_machine.travel("RELEASE_" + animation)
			can_move = true
			
			var pebble = PEBBLE_PATH.instance()
			get_parent().add_child(pebble)
			pebble.position = $Position2D.global_position
			
			if has_slingshot:
				pebble.can_damage = true
				
			pebble_counter -= 1
			get_parent().find_node("UserInterface").update_pebbles(1, "minus", pebble_counter)
			
	if Input.is_action_just_released("shoot"):
		can_move = true
		is_aimining = false
# ------------------------------------------------------------------------------

func block(): # BLOCK INCOMING DAMAGE
	if has_learned_blocking:
		if Input.is_action_just_pressed("block"):
			state_machine.travel('BLOCKING')
			
			if can_jump:
				is_moving = false
			velocity = GRAVITY
			is_blocking = true
			
			if block_timer.time_left <= 0.0:
				block_timer = get_tree().create_timer(0.7)
				if !is_yield_paused:
					yield(block_timer, "timeout")
					is_moving = true
					is_blocking = false
# ------------------------------------------------------------------------------

func rake(): # RAKE LEAVES TO CREATE PILE OF LEAVES
	if has_learned_raking:
		if Input.is_action_just_released("rake"):
			is_raking = false
			$AnimationTree.active = false
			$AnimationTree.active = true
			
		if Input.is_action_pressed("rake") and !is_crouching:
			is_raking = true
			
			if Input.is_action_pressed("right"):
				direction = -1
				$Sprite.flip_h = true
			if Input.is_action_pressed("left"):
				direction = 1
				$Sprite.flip_h = false
			
			velocity.x = -direction * speed / 2
			
			var dir = attack_direction if direction == 0 else -direction
			
			$AnimationTree.set("parameters/RAKING/blend_position", dir)
			state_machine.travel('RAKING')
			for index in $LeavesCollector.get_slide_count():
				var collision = $LeavesCollector.get_slide_collision(index)
				if collision.collider.is_in_group("leaves"):
					collision.collider.apply_central_impulse(collision.normal * 20)
			is_raking = false
			
		# DESTROY A PILE OF LEAVES
		elif Input.is_action_just_pressed("attack") and !is_crouching:
			if state_machine.get_current_node() != "HOLD_PEBBLE":
				state_machine.travel('ATTACK')
# ------------------------------------------------------------------------------

func hit(var dmg):
	if !is_dead:
		Global.level_root().find_node("UserInterface") \
		.update_health(dmg, 'minus', health, max_health)
		health -= dmg
		is_hitted = true
		
		if health > 1:
			var current_animation = state_machine.get_current_node()
			if current_animation == 'HEAVY_ATTACK':
				heavy_attack_counter += 1
				
			state_machine.travel('HIT')
		if !is_yield_paused:
			yield(get_tree().create_timer(0.95, false), "timeout")
			is_hitted = false
# ------------------------------------------------------------------------------

func die(): # CHARACTER DIES
	if !is_dead:
		is_dead = true
		health = 0
		set_collision_layer_bit(1, false)
		velocity = GRAVITY
		state_machine.travel('DEATH')
		Global.is_yield_paused = true
		# Load checkpoint
		if Global.level_root().name != "TutorialLevel":
			SaveLoad.load_from_slot("slot_4")
		yield(get_tree().create_timer(2.2, false), "timeout")
		$AnimationTree.active = false
# ------------------------------------------------------------------------------

func save(): # SAVE VARIABLES IN DICTIONARY
	var saved_data = {
		"health":health,
		"max_health":max_health,
		"pebble_counter":pebble_counter,
		"acorn_counter":acorn_counter,
		"heavy_attack_counter":heavy_attack_counter,
		"speed":speed,
		"damage":damage,
		"has_slingshot":has_slingshot,
		"has_learned_attack":has_learned_attack,
		"has_learned_heavy_attack":has_learned_heavy_attack,
		"has_learned_raking":has_learned_raking,
		"has_learned_blocking":has_learned_blocking
	}
	return saved_data
# ------------------------------------------------------------------------------

func _on_WeaponHitbox_body_entered(body):
	# collision_layer_bit 2 = Enemy
	if body.get_collision_layer_bit(2):
		enemy = body if body.name != "Shield" else body.get_parent()
		can_attack = true
# ------------------------------------------------------------------------------

func _on_WeaponHitbox_body_exited(body):
	# collision_layer_bit 2 = Enemy
	if body.get_collision_layer_bit(2):
		enemy = null
		can_attack = false
# ------------------------------------------------------------------------------

func _draw(): # ENGINE DRAW FUNCTION
	if is_aimining:
		draw_line(Vector2(0, 0), mouse_position, Color(1.0, 1.0, 1.0, 0.3), 8.0)
# ------------------------------------------------------------------------------

func set_values(data):
	for value in data:
		if value == "pos" or \
			value == "file" or \
			value == "parent":
			continue
		print(typeof(value)," - ",value,": ",data[value])
		self.set(value, data[value])
