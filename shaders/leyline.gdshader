shader_type canvas_item;

uniform float x_speed = 0.01;
uniform float y_speed = 0.01;
uniform float alpha: hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	vec2 warped_uv = UV + vec2(sin(TIME * x_speed), cos(TIME * y_speed));
	vec4 original = texture(TEXTURE, warped_uv);
	COLOR = vec4(original.rgb, alpha * original.a);
}