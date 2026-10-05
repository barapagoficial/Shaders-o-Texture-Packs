#version 120

/* ==========================================================================
   Andes Shaders - Ojos brillantes (aranas, enderman, dragon...)
   ========================================================================== */

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    gl_Position = ftransform();

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
}
