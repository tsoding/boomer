#version 130
in vec3 aPos;
in vec2 aTexCoord;
out vec2 texcoord;
uniform vec2 cameraPos;
uniform float cameraScale;
uniform vec2 aspectRatio;
void main()
{
	gl_Position = vec4((aPos.x - cameraPos.x) * cameraScale / aspectRatio.x,
                       (aPos.y + cameraPos.y) * cameraScale / aspectRatio.y,
                       0.0, 1.0);
	texcoord = aTexCoord;
}
