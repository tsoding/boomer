#version 130
in vec3 aPos;
in vec2 aTexCoord;
out vec2 texcoord;
uniform vec2 cameraPos;
uniform float cameraScale;
uniform vec2 windowSize;
uniform vec2 screenshotSize;

vec2 ratio = vec2(
    windowSize.x / screenshotSize.x,
    windowSize.y / screenshotSize.y);

void main()
{
	gl_Position = vec4((aPos.x - cameraPos.x) * cameraScale / ratio.x,
                       (aPos.y + cameraPos.y) * cameraScale / ratio.y,
                       0.0, 1.0);
	texcoord = aTexCoord;
}
