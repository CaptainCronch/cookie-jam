shader_type canvas_item;

uniform float size : hint_range(1.0, 100.0) = 25.0;
uniform vec4 color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform vec4 color2 : source_color = vec4(0.0, 0.0, 0.0, 0.0); 
uniform float tolerance;
uniform vec4 overlap_color: source_color;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

bool close_enough(vec3 a, vec3 b){
	vec3 difference = abs(a - b);
	if (difference.x < tolerance && difference.y < tolerance && difference.z < tolerance){
		return true;
	}else{
		return false;
	}
}

void fragment() {
	vec2 pos = floor(FRAGCOORD.xy / size);
	float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
	
	vec4 original_color = texture(TEXTURE, UV);
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	if (close_enough(screen_color.rgb, original_color.rgb)){
		COLOR.rgb = original_color.rgb;
	}else{
		COLOR = mix(color1, color2, pattern_mask);
	}
	COLOR.a = original_color.a;
}
