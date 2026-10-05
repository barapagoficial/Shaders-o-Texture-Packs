/* ==========================================================================
   Andes Shaders - Niebla
   Incluye los uniforms de niebla y la funcion que aplica la niebla vanilla
   mezclandola con la opcion HORIZON_FOG del pack.
   ========================================================================== */
#ifndef ANDES_FOG_GLSL
#define ANDES_FOG_GLSL

#include "/lib/common.glsl"

uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform float far;

/* Mezcla el color con la niebla segun la distancia (en bloques) */
vec3 applyFog(vec3 color, float dist) {
    float mult = max(HORIZON_FOG, 0.05);
    float s = fogStart / mult;
    float e = fogEnd / mult;

    // Si el juego no da distancias de niebla validas usamos la distancia de render
    if (e < s + 1.0) {
        float d = max(far, 32.0);
        s = d * 0.65 / mult;
        e = d * 1.15 / mult;
    }

    float f = sat((dist - s) / max(e - s, 1.0));
    return mix(color, fogColor, f);
}

#endif
