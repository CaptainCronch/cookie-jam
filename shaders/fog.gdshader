shader_type canvas_item;

uniform float size : hint_range(1.0, 100.0) = 16.0;
uniform float speed : hint_range(1.0, 100.0) = 20.0;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	pixel.a -= pixel.r;
	
	vec2 pos = floor((FRAGCOORD.xy + vec2(TIME * speed, 0.0)) / size);
	float reverse = (pixel.r * -1.0) + 1.0;
	float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0) * reverse;
	
	pixel.rgb = vec3(0.0);
	COLOR = mix(pixel, color, pattern_mask);
}
