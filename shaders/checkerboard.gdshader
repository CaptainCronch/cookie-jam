shader_type canvas_item;

uniform float size : hint_range(1.0, 100.0) = 25.0;
uniform float speed : hint_range(-100.0, 100.0) = 20.0;
uniform float speed_factor = 1.0;
uniform vec4 color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform vec4 color2 : source_color = vec4(0.7, 0.7, 0.7, 1.0);
uniform vec4 color3 : source_color = vec4(0.7, 0.7, 0.7, 1.0);

void fragment() {
	vec2 pos = floor((FRAGCOORD.xy + vec2(TIME * speed * speed_factor)) / size);
	vec2 pos_small = floor((FRAGCOORD.xy + vec2(-TIME * speed*2.0 * speed_factor, TIME * speed*2.0 * speed_factor)) / (size*2.0));
	float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
	float pattern_mask_small = mod(pos_small.x + mod(pos_small.y, 2.0), 2.0);
	vec4 pre = mix(color1, color2, pattern_mask);
	COLOR = mix(pre, color3, pattern_mask_small);
}