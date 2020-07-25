extends KinematicBody2D

export var speed = 300
export var jumpStrength = 450

var Velocity = Vector2()
const Gravity = Vector2(0,25)
var bCanJump = false
var bSlowMotion = false

func _process(delta):
	Velocity.x = speed if !bSlowMotion else speed / 2
	Velocity.y += Gravity.y if !bSlowMotion else Gravity.y / 7
	Jump()
	Crouch()
	Velocity = move_and_slide(Velocity)
# ------------------------------------------------------------------------------
func Jump(): # JUMP
	if Input.is_action_just_pressed("jump"):
		bCanJump = true if $GroundRay.is_colliding() else false
			
		if bCanJump:
			Velocity.y = -jumpStrength if !bSlowMotion else -jumpStrength / 2.5
# ------------------------------------------------------------------------------
func Crouch():
	if Input.is_action_pressed("crouch"):
		$CollisionShape2D.position.y = 30
		$CollisionShape2D.scale.y = 0.6
		$AnimatedSprite.position.y = 30
		$AnimatedSprite.scale.y = 0.25
		Velocity.x = speed / 1.3 if !bSlowMotion else speed / 3.5
	else:
		$CollisionShape2D.position.y = 0
		$CollisionShape2D.scale.y = 1
		$AnimatedSprite.position.y = 0
		$AnimatedSprite.scale.y = 0.4
# ------------------------------------------------------------------------------