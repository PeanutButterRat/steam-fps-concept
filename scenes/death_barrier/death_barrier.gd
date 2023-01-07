extends Area


func _on_DeathBarrier_body_entered(body: Node) -> void:
	if body is Mob:
		var data: Array = [body.id, randi(), Mob.WORLD_ID]
		Global.send_signal(Global.Signals.MOB_KILLED, data)
