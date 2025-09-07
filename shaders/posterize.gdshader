shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable;
uniform int levels = 16;

void fragment(){
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
    float r = floor(color.r * float(levels)) / float(levels);
    float g = floor(color.g * float(levels)) / float(levels);
    float b = floor(color.b * float(levels)) / float(levels);
    COLOR = vec4(r, g, b, color.a);
}