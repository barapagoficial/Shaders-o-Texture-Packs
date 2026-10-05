/* ==========================================================================
   Andes Shaders - Iluminacion y sombras
   ========================================================================== */
#ifndef ANDES_LIGHTING_GLSL
#define ANDES_LIGHTING_GLSL

#include "/lib/common.glsl"
#include "/lib/shadows.glsl"

uniform sampler2D lightmap;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform float alphaTestRef;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef SHADOWS
uniform sampler2D shadowtex1;
#endif

/* 0.0 = noche cerrada, 1.0 = pleno dia */
float getDayFactor() {
    vec3 sunDirWorld = mat3Of(gbufferModelViewInverse) * normalize(sunPosition);
    return sat(smoothstep(-0.08, 0.22, sunDirWorld.y));
}

#ifdef SHADOWS
/* 9 muestras de Poisson/disco sobre el mapa de sombras para penumbras suaves sin rejilla */
float sampleShadowPCF(vec2 uv, float z, float bias) {
    float texel = SHADOW_TEXEL_SIZE * SHADOW_SOFTNESS;
    float s = 0.0;

    s += step(z - bias, texture2D(shadowtex1, uv).r) * 2.0;
    s += step(z - bias, texture2D(shadowtex1, uv + vec2(-1.0,  0.0) * texel).r);
    s += step(z - bias, texture2D(shadowtex1, uv + vec2( 1.0,  0.0) * texel).r);
    s += step(z - bias, texture2D(shadowtex1, uv + vec2( 0.0, -1.0) * texel).r);
    s += step(z - bias, texture2D(shadowtex1, uv + vec2( 0.0,  1.0) * texel).r);
    s += step(z - bias, texture2D(shadowtex1, uv + vec2(-0.8, -0.8) * texel).r) * 0.75;
    s += step(z - bias, texture2D(shadowtex1, uv + vec2( 0.8, -0.8) * texel).r) * 0.75;
    s += step(z - bias, texture2D(shadowtex1, uv + vec2(-0.8,  0.8) * texel).r) * 0.75;
    s += step(z - bias, texture2D(shadowtex1, uv + vec2( 0.8,  0.8) * texel).r) * 0.75;

    return s / 9.0;
}
#endif

/* Factor de sombra: 1.0 = iluminado, 0.0 = en sombra.
   shadowPos      = coordenadas del mapa de sombras (varying)
   normalView     = normal en espacio de vista (varying)
   lightDirView   = direccion de la luz en espacio de vista (uniform)
   distFromCamera = distancia del fragmento a la camara */
float getShadow(vec3 shadowPos, vec3 normalView, vec3 lightDirView, float distFromCamera) {
#ifdef SHADOWS
    float shadow = 1.0;

    // Normal segura
    vec3 nrm = normalView;
    float lenSq = dot(nrm, nrm);
    if (lenSq > 0.0001) {
        nrm *= inversesqrt(lenSq);
    } else {
        nrm = vec3(0.0, 1.0, 0.0);
    }

    vec3 lDir = normalize(lightDirView);
    float NdotL = dot(nrm, lDir);

    // Si la superficie da la espalda a la fuente de luz, esta naturalmente en su propia sombra.
    // Esto previene que la luz atraviese paredes, techos o suelos.
    if (NdotL <= 0.0) {
        return 0.0;
    }

    if (shadowPos.x > 0.001 && shadowPos.x < 0.999 &&
        shadowPos.y > 0.001 && shadowPos.y < 0.999 &&
        shadowPos.z < 1.0) {
        // Sesgo dinamico dependiente de la pendiente para evitar acné de sombras
        float bias = SHADOW_BIAS_BASE + SHADOW_BIAS_SLOPE * (1.0 - sat(NdotL));
        shadow = sampleShadowPCF(shadowPos.xy, shadowPos.z, bias);
    }

    // Suavizado en los bordes del mapa de sombras
    vec2 edge = min(shadowPos.xy, vec2(1.0) - shadowPos.xy);
    float border = sat(min(edge.x, edge.y) / 0.06);

    // Desvanecimiento suave con la distancia
    float fade = sat((shadowDistance - distFromCamera) / (shadowDistance * 0.25));

    // Modulacion difusa suave segun angulo con la luz
    shadow *= smoothstep(0.0, 0.15, NdotL);

    return mix(1.0, shadow, border * fade);
#else
    return 1.0;
#endif
}

/* Iluminacion completa de superficies:
   - Luz de bloques (antorchas, faroles, lava, luz dinamica en mano) calculada de forma independiente
   - Luz solar/lunar directa modulada por sombras
   - Luz ambiental difusa del cielo (rebote frio dentro de sombras)
   - Ambiencia base para interiores y noche */
vec3 shadeSurface(vec3 albedo, vec2 lmcoord, float shadow, float dayF, float dist) {
    // --- 1. Luz de bloques (antorchas, faroles, etc.) ---
    float blockRaw = sat((lmcoord.x - 0.032) / 0.936);

    // Luz dinamica al sostener antorchas/faroles en la mano
    float heldLight = max(float(heldBlockLightValue), float(heldBlockLightValue2)) / 15.0;
    float handDynamic = 0.0;
    if (heldLight > 0.0 && dist > 0.0) {
        float handRange = heldLight * 16.0;
        handDynamic = heldLight * sat(1.0 - dist / handRange);
        handDynamic = handDynamic * handDynamic; // caida cuadratica
    }

    float totalBlock = max(blockRaw, handDynamic);
    float torchCurve = pow(totalBlock, 1.85);

#ifdef BLOCKLIGHT_TINT
    vec3 torchColor = vec3(1.15, 0.72, 0.32);
#else
    vec3 torchColor = vec3(1.00, 0.82, 0.60);
#endif

    // Las antorchas iluminan con intensidad calida y NO se apagan por sombras solares
    vec3 torchLight = torchColor * (torchCurve * 1.55);

    // --- 2. Luz de cielo y luz directa solar/lunar ---
    float skyRaw = sat((lmcoord.y - 0.032) / 0.936);
    float skyCurve = pow(skyRaw, 1.4);

    vec3 sunDirect = vec3(1.20, 1.14, 1.02);
    vec3 moonDirect = vec3(0.18, 0.26, 0.42) * NIGHT_BRIGHTNESS;
    vec3 directColor = mix(moonDirect, sunDirect, dayF);

    // Luz directa: requiere estar expuesto al cielo Y no estar en sombra
    vec3 directLight = directColor * (skyCurve * shadow);

    // Luz ambiental difusa del cielo (llega en sombras mientras haya cielo abierto)
    vec3 skyAmbientDay = mix(vec3(0.35, 0.44, 0.58), vec3(0.48, 0.44, 0.40), 1.0 - SHADOW_COLOR * 0.5);
    vec3 skyAmbientNight = vec3(0.06, 0.09, 0.16) * NIGHT_BRIGHTNESS;
    vec3 skyAmbientColor = mix(skyAmbientNight, skyAmbientDay, dayF);

    vec3 ambientSky = skyAmbientColor * (skyCurve * mix(0.40, 0.75, 1.0 - shadow));

    // Luz ambiental minima para cuevas e interiores sin antorchas
    vec3 minAmbient = vec3(0.030, 0.032, 0.038) * mix(NIGHT_BRIGHTNESS, 1.0, dayF);

    // Combinacion final
    vec3 totalLight = minAmbient + torchLight + directLight + ambientSky;

    return albedo * totalLight;
}

/* Sobrecarga para llamadas que no pasan la distancia */
vec3 shadeSurface(vec3 albedo, vec2 lmcoord, float shadow, float dayF) {
    return shadeSurface(albedo, lmcoord, shadow, dayF, 0.0);
}

#endif
