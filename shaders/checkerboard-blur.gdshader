shader_type canvas_item;

uniform float size : hint_range(1.0, 100.0) = 16.0;
uniform float speed : hint_range(-100.0, 100.0) = 20.0;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.0); 
uniform float outer_radius : hint_range(0.0, 1.0) = 1.0;
uniform float main_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 pos = floor((FRAGCOORD.xy + vec2(TIME * speed)) / size);
	float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
	
	float x = abs((UV.x*-1.0)+0.5)-.5;//abs(UV.x-.5)*2.0;
	float y = abs((UV.y*-1.0)+0.5)-.5;//abs(UV.y-.5)*2.0;
	float v = (sqrt((x*x)+(y*y))/outer_radius);
	
	COLOR = vec4(COLOR.rgb, v * main_alpha);
	COLOR = mix(color, COLOR, pattern_mask);
}