#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
out vec2 texcoord;
uniform mat4 transform;
void main()
{
	gl_Position = transform * vec4(aPos, 1.0f);
	texcoord = aTexCoord;
}
