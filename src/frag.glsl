#version 130
out mediump vec4 color;
in mediump vec2 texcoord;
uniform sampler2D tex;
uniform vec2 cursorPos;
uniform vec2 windowSize;
uniform float flShadow;

const float FLASHLIGHT_RADIUS = 200.0;

void main()
{
    vec4 cursor = vec4(cursorPos.x, windowSize.y - cursorPos.y, 0.0, 1.0);
    if (length(cursor - gl_FragCoord) < FLASHLIGHT_RADIUS) {
        color = texture(tex, texcoord);
    } else {
        color = texture(tex, texcoord) - vec4(flShadow, flShadow, flShadow, 0.0);
    }
}
