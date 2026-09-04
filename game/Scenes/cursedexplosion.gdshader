shader_type canvas_item;

// Allows us to read the pixels behind this ColorRect
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool active = false;

void fragment() {
    vec4 color = texture(screen_texture, SCREEN_UV);
    if (active) {
        // Invert the RGB channels but keep the original opacity (Alpha)
        COLOR = vec4(1.0 - color.rgb, color.a);
    } else {
        COLOR = color;
    }
}
