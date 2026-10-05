#version 120

/* ==========================================================================
   Andes Shaders - Lluvia y nieve
   ========================================================================== */

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;

    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vViewPos = viewPos.xyz;
}
