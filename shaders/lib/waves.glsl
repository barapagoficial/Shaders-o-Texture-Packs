/* ==========================================================================
   Andes Shaders - Viento y olas
   Solo declara uniforms escalares para poder incluirse tambien desde los
   fragment shaders (las matrices las declara cada programa que las necesita).
   ========================================================================== */
#ifndef ANDES_WAVES_GLSL
#define ANDES_WAVES_GLSL

#include "/lib/common.glsl"

uniform float frameTimeCounter;

/* --- Movimiento de plantas (hierba, flores, cultivos) ---
   heightFrac = 0.0 en la base (fijo al suelo), 1.0 en la punta (maximo vaiven).
   blockCoord = centro del bloque para mantener fase consistente. */
vec3 plantWindOffset(vec3 worldPos, vec3 blockCoord, float heightFrac, float strength, float speed) {
    if (heightFrac < 0.01) return vec3(0.0);

    float t = frameTimeCounter * speed;
    float phase = blockCoord.x * 0.28 + blockCoord.z * 0.32;

    // Onda principal suave en direccion dominante del viento
    float mainWave = sin(t + phase);
    // Armonico secundario para dar organicidad sin temblores
    float subWave  = sin(t * 0.62 - phase * 0.75);

    float dispX = (mainWave * 0.70 + subWave * 0.30) * strength * heightFrac;
    float dispZ = (mainWave * 0.45 - subWave * 0.55) * strength * heightFrac;
    // Pequena caida vertical natural cuando la planta se inclina
    float dispY = -abs(dispX + dispZ) * 0.18 * heightFrac;

    return vec3(dispX, dispY, dispZ);
}

/* --- Movimiento suave de las hojas de los arboles ---
   CRITICO: se calcula usando blockCoord para que TODOS los vertices del bloque
   de hojas se desplacen exactamente igual, evitando desmembramiento y temblores.
   Usa frecuencias bajas para que la copa entera del arbol respire con la brisa. */
vec3 leavesWindOffset(vec3 blockCoord, float strength, float speed) {
    float t = frameTimeCounter * (speed * 0.85);

    // Ondas espaciales continuas a escala de arbol (longitud de onda ~4-8 bloques)
    float waveX = sin(t + blockCoord.x * 0.22 + blockCoord.z * 0.18);
    float waveZ = cos(t * 0.75 - blockCoord.x * 0.16 + blockCoord.z * 0.24);
    float waveSub = sin(t * 1.30 + blockCoord.x * 0.40 - blockCoord.z * 0.35);

    float dispX = (waveX * 0.75 + waveSub * 0.25) * strength;
    float dispZ = (waveZ * 0.75 - waveSub * 0.25) * strength;
    float dispY = (waveX * waveZ) * strength * 0.20;

    return vec3(dispX, dispY, dispZ);
}

/* Version de compatibilidad para llamadas genericas de viento */
vec3 windOffset(vec3 worldPos, float strength, float speed, float seed) {
    float t = frameTimeCounter * (speed * 0.9);
    float f1 = sin(t + worldPos.x * 0.25 + worldPos.z * 0.28 + seed * 0.2);
    float f2 = cos(t * 0.70 - worldPos.z * 0.20 + worldPos.x * 0.18 + seed * 0.3);
    return vec3(
        (f1 * 0.65 + f2 * 0.35) * strength,
        (f1 * f2) * strength * 0.15,
        (f2 * 0.65 - f1 * 0.35) * strength
    );
}

/* --- Altura de la superficie del agua con olas multi-octava --- */
float waterWaveHeight(vec3 worldPos, float amount) {
    float t = frameTimeCounter * (WIND_SPEED * 1.15);

    // Octava 1: oleaje principal suave (longitud de onda amplia)
    float w1 = sin(worldPos.x * 0.42 + worldPos.z * 0.35 + t * 1.1) * 0.50;
    // Octava 2: oleaje cruzado que rompe la monotonia
    float w2 = cos(worldPos.x * 0.26 - worldPos.z * 0.46 + t * 0.85) * 0.35;
    // Octava 3: micro-rizos superficiales para destellos de luz
    float w3 = sin((worldPos.x + worldPos.z) * 0.78 + t * 1.55) * 0.15;

    return (w1 + w2 + w3) * amount;
}

/* Alias de compatibilidad */
float waterWave(vec3 worldPos, float amount) {
    return waterWaveHeight(worldPos, amount);
}

/* --- Normal de la superficie del agua calculada con alta precision ---
   Usa un delta ajustado (0.08) para capturar los rizos finos y brillos solares. */
vec3 waterSurfaceNormal(vec3 worldPos, float amount) {
    float d = 0.08;
    float h  = waterWaveHeight(worldPos, amount);
    float hx = waterWaveHeight(worldPos + vec3(d, 0.0, 0.0), amount);
    float hz = waterWaveHeight(worldPos + vec3(0.0, 0.0, d), amount);

    float nx = -(hx - h) / d;
    float nz = -(hz - h) / d;
    return normalize(vec3(nx, 1.0, nz));
}

/* Alias de compatibilidad */
vec3 waterNormal(vec3 worldPos, float amount) {
    return waterSurfaceNormal(worldPos, amount);
}

#endif
