#version 130
in vec3 aPos;
in vec2 aTexCoord;
out vec2 texcoord;

uniform vec2 cameraPos;
uniform float cameraScale;
uniform vec2 windowSize;
uniform vec2 screenshotSize;
uniform vec2 cursorPos;

vec3 to_world(vec3 v) {
    vec2 ratio = vec2(
        windowSize.x / screenshotSize.x / cameraScale,
        windowSize.y / screenshotSize.y / cameraScale);
    return vec3((v.x / screenshotSize.x * 2.0 - 1.0) / ratio.x,
                (v.y / screenshotSize.y * 2.0 - 1.0) / ratio.y,
                v.z);
}

void main()
{
	gl_Position = vec4(to_world((aPos - vec3(cameraPos * vec2(1.0, -1.0), 0.0))), 1.0);
	texcoord = aTexCoord;
}
