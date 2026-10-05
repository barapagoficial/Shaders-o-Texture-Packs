/* ==========================================================================
   Andes Shaders - Funciones de utilidad (sin uniforms)
   ========================================================================== */
#ifndef ANDES_COMMON_GLSL
#define ANDES_COMMON_GLSL

#include "/lib/settings.glsl"

/* --- Saturacion ---------------------------------------------------------- */
float sat(float x) { return clamp(x, 0.0, 1.0); }
vec2  sat(vec2 x)  { return clamp(x, 0.0, 1.0); }
vec3  sat(vec3 x)  { return clamp(x, 0.0, 1.0); }
vec4  sat(vec4 x)  { return clamp(x, 0.0, 1.0); }

/* --- Luminancia ---------------------------------------------------------- */
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

/* --- Extrae la parte rotacional de una matriz ---------------------------- */
mat3 mat3Of(mat4 m) { return mat3(m[0].xyz, m[1].xyz, m[2].xyz); }

/* --- Ruido por hash (sin operadores de bits, valido en GLSL 1.20) -------- */
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/* --- Mapeo de tonos ------------------------------------------------------ */
vec3 tonemapSoft(vec3 c) {
    vec3 a = c * 1.15;
    return a / (1.0 + 0.35 * a);
}

vec3 tonemapFilmic(vec3 c) {
    // Aproximacion de la curva ACES (Narkowicz)
    vec3 x = max(c * 1.05, vec3(0.0));
    return sat((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14));
}

/* --- Correccion de color ------------------------------------------------- */
vec3 applyGrading(vec3 c) {
    c = (c - 0.5) * CONTRAST + 0.5;
    float l = luma(c);
    c = mix(vec3(l), c, SATURATION);
    return sat(c);
}

/* --- Vineta -------------------------------------------------------------- */
float vignetteFactor(vec2 uv, float aspect) {
    vec2 d = (uv - 0.5) * vec2(aspect, 1.0);
    float vig = sat(1.0 - dot(d, d) * 0.42);
    vig = vig * vig * vig;
    return mix(1.0, vig, VIGNETTE);
}

/* --- Respaldo de las etapas de render (Iris las define por su cuenta) ----- */
#ifndef MC_RENDER_STAGE_SKY
#define MC_RENDER_STAGE_SKY -1
#define MC_RENDER_STAGE_SUNSET -1
#define MC_RENDER_STAGE_SUN -1
#define MC_RENDER_STAGE_MOON -1
#define MC_RENDER_STAGE_STARS -1
#define MC_RENDER_STAGE_VOID -1
#endif

#endif
