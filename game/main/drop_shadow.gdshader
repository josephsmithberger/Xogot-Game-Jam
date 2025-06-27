shader_type canvas_item;

uniform vec2 shadow_offset      = vec2(4.0, -4.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
    // pixel size in UV space
    vec2 pix = 1.0 / vec2(textureSize(TEXTURE, 0));
    
    // sample shadow from offset sprite
    vec2 off_uv = UV + shadow_offset * pix;
    vec4 sh = texture(TEXTURE, off_uv);
    sh.rgb = shadow_color.rgb;
    sh.a *= shadow_color.a;
    
    // sample main sprite
    vec4 spr = texture(TEXTURE, UV) * COLOR;
    
    // composite: shadow where sprite is transparent
    COLOR = sh * (1.0 - spr.a) + spr;
}



