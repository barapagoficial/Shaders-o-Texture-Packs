#version 120

/* ==========================================================================
   Andes Shaders - Cielo (degradado, resplandor solar, estrellas, vacio)
   ========================================================================== */

uniform mat4 gbufferModelViewInverse;

varying vec3 vWorldDir;
varying vec4 vColor;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 playerPos = gbufferModelViewInverse * viewPos;

    gl_Position = gl_ProjectionMatrix * viewPos;

    vWorldDir = playerPos.xyz;
    vColor = gl_Color;
}
