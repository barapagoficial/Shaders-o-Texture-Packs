#version 120

/* ==========================================================================
   Andes Shaders - Geometria con textura sin iluminacion
   ========================================================================== */

varying vec2 texcoord;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;

    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
    vViewPos = viewPos.xyz;
}
