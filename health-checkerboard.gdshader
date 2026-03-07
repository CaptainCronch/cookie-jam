shader_type canvas_item;

uniform float size : hint_range(1.0, 100.0) = 16.0;
uniform float speed : hint_range(1.0, 100.0) = 20.0;
uniform float speed_boost : hint_range(-100000.0, 100000.0) = -99999.0;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float level : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 pos = floor((FRAGCOORD.xy + vec2(TIME * speed - speed_boost, 0.0)) / size);
	float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
	if (UV.y < level){
		pattern_mask = 1.0;
	}
	COLOR = mix(color, COLOR, pattern_mask);
}
