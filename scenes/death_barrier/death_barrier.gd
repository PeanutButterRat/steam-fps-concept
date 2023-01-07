extends Area


func _on_DeathBarrier_body_entered(body: Node) -> void:
	if body is Mob:
		body.damage(body.health, Mob.WORLD_ID)
