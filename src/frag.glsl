#version 130
out mediump vec4 color;
in mediump vec2 texcoord;
uniform sampler2D tex;
uniform vec2 cursorPos;
uniform vec2 windowSize;
uniform float flShadow;
uniform float flRadius;

void main()
{
    vec4 cursor = vec4(cursorPos.x, windowSize.y - cursorPos.y, 0.0, 1.0);
    color = mix(
        texture(tex, texcoord), vec4(0.0, 0.0, 0.0, 0.0),
        length(cursor - gl_FragCoord) < flRadius ? 0.0 : flShadow);
}
