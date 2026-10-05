#version 120

/* ==========================================================================
   Andes Shaders - Lineas (contorno del bloque, sedal de pesca)
   ========================================================================== */

varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;

    gl_Position = gl_ProjectionMatrix * viewPos;

    vColor = gl_Color;
    vViewPos = viewPos.xyz;
}
