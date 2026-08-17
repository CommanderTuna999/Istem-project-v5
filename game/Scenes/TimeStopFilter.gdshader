shader_type canvas_item;

// Grab whatever is currently being rendered to the viewport window behind this rect
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    // Get the authentic color of the pixel on screen
    vec4 pixel_color = texture(screen_texture, SCREEN_UV);
    
    // Apply standard luminosity weights to compute grayscale matching human brightness perception
    float grayscale = (pixel_color.r * 0.299) + (pixel_color.g * 0.587) + (pixel_color.b * 0.114);
    
    // Output the gray shade while maintaining the alpha channel intact
    COLOR = vec4(vec3(grayscale), pixel_color.a);
}
