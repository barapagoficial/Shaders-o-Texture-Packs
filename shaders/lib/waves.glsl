/* ==========================================================================
   Andes Shaders - Viento y olas
   Solo declara uniforms escalares para poder incluirse tambien desde los
   fragment shaders (las matrices las declara cada programa que las necesita).
   ========================================================================== */
#ifndef ANDES_WAVES_GLSL
#define ANDES_WAVES_GLSL

#include "/lib/common.glsl"

uniform float frameTimeCounter;

/* Desplazamiento de viento para una posicion del mundo (alineado con el mundo) */
vec3 windOffset(vec3 worldPos, float strength, float speed, float seed) {
    float t = frameTimeCounter * speed;
    float f1 = sin(t + worldPos.x * 0.32 + worldPos.z * 0.41 + seed);
    float f2 = sin(t * 0.63 - worldPos.z * 0.28 + worldPos.x * 0.19 + seed * 1.7);
    float f3 = cos(t * 1.17 + worldPos.x * 0.12 - worldPos.z * 0.15 + seed * 2.3);
    return vec3(
        (f1 * 0.55 + f2 * 0.45) * strength,
        (f1 + f2 * 0.60) * strength * 0.22,
        (f2 * 0.55 - f1 * 0.35 + f3 * 0.25) * strength
    );
}

/* Altura de la ola (en bloques) para una posicion del mundo */
float waterWave(vec3 worldPos, float amount) {
    float t = frameTimeCounter * 1.1 * WIND_SPEED;
    float w = sin(worldPos.x * 0.55 + t) * 0.5 + cos(worldPos.z * 0.48 + t * 1.35) * 0.5;
    w += sin((worldPos.x + worldPos.z) * 0.22 + t * 0.7) * 0.35;
    return w * amount;
}

/* Normal (en el mundo) de la superficie del agua con olas */
vec3 waterNormal(vec3 worldPos, float amount) {
    float d = 0.35;
    float h  = waterWave(worldPos, amount);
    float hx = waterWave(worldPos + vec3(d, 0.0, 0.0), amount);
    float hz = waterWave(worldPos + vec3(0.0, 0.0, d), amount);
    return normalize(vec3(-(hx - h) / d, 1.0, -(hz - h) / d));
}

#endif
