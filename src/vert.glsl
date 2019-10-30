#version 130
in vec3 aPos;
in vec2 aTexCoord;
out vec2 texcoord;
uniform vec2 cameraPos;
uniform float cameraScale;
void main()
{
	gl_Position = vec4((aPos.x - cameraPos.x) * cameraScale, (aPos.y + cameraPos.y) * cameraScale, 0.0, 1.0);
	texcoord = aTexCoord;
}
