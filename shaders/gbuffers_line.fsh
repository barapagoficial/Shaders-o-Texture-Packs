#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Lineas
   El contorno del bloque se mantiene tal cual (color y transparencia).
   ========================================================================== */

#include "/lib/fog.glsl"

varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    float dist = length(vViewPos);
    vec3 color = applyFog(vColor.rgb, dist);
    gl_FragData[0] = vec4(color, vColor.a);
}
