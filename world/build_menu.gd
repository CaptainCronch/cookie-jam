@warning_ignore("missing_tool")
extends RadialMenuAdvanced

#var shader_offset := Vector2()
#var shader_speed := 200.0
#var shader_acceleration := 0.5
#
#
#func _process(delta: float) -> void:
	#var desired_shader_offset := Vector2(randfn(0.0, shader_speed), randfn(0.0, shader_speed))
	#shader_offset = Global.decay_towards_vec2(shader_offset, desired_shader_offset, shader_acceleration, delta)
	#(material as ShaderMaterial).set_shader_parameter("offset", shader_offset)
