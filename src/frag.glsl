#version 130
out mediump vec4 color;
in mediump vec2 texcoord;
uniform sampler2D tex;
void main()
{
    color = texture(tex, texcoord);
}
