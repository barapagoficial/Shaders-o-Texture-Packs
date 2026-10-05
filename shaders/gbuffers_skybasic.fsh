#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Cielo
   Degradado entre el color del horizonte y el color del cenit, resplandor
   del sol, banda de puesta de sol, estrellas generadas por procedimiento y
   color oscuro para el vacio (por debajo del mundo).
   ========================================================================== */

#include "/lib/common.glsl"

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform mat4 gbufferModelViewInverse;
uniform int renderStage;

varying vec3 vWorldDir;
varying vec4 vColor;

void main() {
#ifdef CUSTOM_SKY
    vec3 dir = normalize(vWorldDir);
    float upness = sat(dir.y);

    vec3 sunDir = normalize(mat3Of(gbufferModelViewInverse) * sunPosition);
    vec3 moonDir = normalize(mat3Of(gbufferModelViewInverse) * moonPosition);
    float dayF = sat(smoothstep(-0.08, 0.22, sunDir.y));

    // --- Vacio (por debajo del mundo) ---
    if (renderStage == MC_RENDER_STAGE_VOID) {
        gl_FragData[0] = vec4(fogColor * 0.15, 1.0);
        return;
    }

    // --- Degradado del cielo ---
    vec3 sky = mix(fogColor, skyColor, pow(upness, 0.55));

    // --- Banda de puesta de sol / amanecer alrededor del sol ---
    float sunAmount = sat(dot(dir, sunDir));
    float horizonF = pow(1.0 - upness, 3.0);
    float sunsetBand = sat(pow(sunAmount, 4.0) * horizonF * 1.6);
    sky += vec3(1.0, 0.45, 0.18) * sunsetBand * 0.75;

    // --- Resplandor del sol y de la luna ---
    sky += vec3(1.0, 0.92, 0.75) * pow(sunAmount, 90.0) * SUN_GLOW * 1.5;
    float moonAmount = sat(dot(dir, moonDir));
    sky += vec3(0.72, 0.80, 1.0) * pow(moonAmount, 120.0) * SUN_GLOW * (1.0 - dayF) * 0.7;

    // --- Estrellas por la noche ---
    float nightF = 1.0 - dayF;
    if (nightF > 0.01 && dir.y > -0.02) {
        vec2 starUv = dir.xz / max(abs(dir.y) + 0.4, 0.15) * 1.7;
        float cell = hash12(floor(starUv * 85.0) + 0.5);
        float star = pow(sat(cell - 0.985) * 66.0, 1.5);
        // parpadeo lento
        star *= 0.75 + 0.25 * hash12(floor(starUv * 85.0) + 1.5);
        sky += vec3(0.90, 0.94, 1.0) * star * nightF * STARS * 1.6;
    }

    gl_FragData[0] = vec4(sky, 1.0);
#else
    gl_FragData[0] = vColor;
#endif
}
