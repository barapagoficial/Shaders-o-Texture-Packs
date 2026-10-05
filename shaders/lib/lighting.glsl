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

#ifdef SHADOWS
uniform sampler2D shadowtex1;
#endif

/* 0.0 = noche cerrada, 1.0 = pleno dia */
float getDayFactor() {
    vec3 sunDirWorld = mat3Of(gbufferModelViewInverse) * normalize(sunPosition);
    return sat(smoothstep(-0.08, 0.22, sunDirWorld.y));
}

#ifdef SHADOWS
/* 4 muestras (PCF) sobre el mapa de sombras */
float sampleShadowPCF(vec2 uv, float z, float bias) {
    float texel = SHADOW_TEXEL_SIZE * SHADOW_SOFTNESS;
    float s = 0.0;
    s += step(z - bias, texture2D(shadowtex1, uv + vec2(-1.0, -1.0) * texel).r);
    s += step(z - bias, texture2D(shadowtex1, uv + vec2( 1.0, -1.0) * texel).r);
    s += step(z - bias, texture2D(shadowtex1, uv + vec2(-1.0,  1.0) * texel).r);
    s += step(z - bias, texture2D(shadowtex1, uv + vec2( 1.0,  1.0) * texel).r);
    return s * 0.25;
}
#endif

/* Factor de sombra: 1.0 = iluminado, 0.0 = en sombra.
   shadowPos  = coordenadas del mapa de sombras (varying)
   normalView = normal en espacio de vista (varying)
   lightDirView = direccion de la luz en espacio de vista (uniform)
   distFromCamera = distancia del fragmento a la camara */
float getShadow(vec3 shadowPos, vec3 normalView, vec3 lightDirView, float distFromCamera) {
#ifdef SHADOWS
    float shadow = 1.0;

    if (shadowPos.x > 0.0 && shadowPos.x < 1.0 && shadowPos.y > 0.0 && shadowPos.y < 1.0 && shadowPos.z < 1.0) {
        vec3 nrm = normalView;
        if (dot(nrm, nrm) < 0.0001) nrm = vec3(0.0, 1.0, 0.0);
        float dotNL = sat(dot(normalize(nrm), normalize(lightDirView)));

        // Sesgo dependiente del angulo para evitar el "acné" de sombras
        float bias = SHADOW_BIAS_BASE + SHADOW_BIAS_SLOPE * (1.0 - dotNL);
        shadow = sampleShadowPCF(shadowPos.xy, shadowPos.z, bias);
    }

    // Suaviza los bordes del mapa y desvanece las sombras con la distancia
    vec2 edge = min(shadowPos.xy, vec2(1.0) - shadowPos.xy);
    float border = sat(min(edge.x, edge.y) / 0.06);
    float fade = sat((shadowDistance - distFromCamera) / (shadowDistance * 0.2));

    return mix(1.0, shadow, border * fade);
#else
    return 1.0;
#endif
}

/* Iluminacion de superficies (luz del lightmap de Minecraft + sombras) */
vec3 shadeSurface(vec3 albedo, vec2 lmcoord, float shadow, float dayF) {
    vec3 lights = texture2D(lightmap, lmcoord).rgb;

    // La noche se ilumina con NIGHT_BRIGHTNESS
    lights *= 1.0 + (1.0 - dayF) * (NIGHT_BRIGHTNESS - 1.0);

    // Tinte calido para la luz de bloque (antorchas, lava...)
#ifdef BLOCKLIGHT_TINT
    float blockAmt = sat(lmcoord.x * lmcoord.x * 1.5);
    lights *= mix(vec3(1.0), vec3(1.10, 0.99, 0.86), blockAmt);
#endif

    // Solo la parte de luz del cielo se oscurece con las sombras
    float skyMask = sat(lmcoord.y * lmcoord.y * 1.3);
    vec3 color = albedo * lights * mix(1.0, shadow, skyMask);

    // Rebote frio del cielo dentro de las sombras
    color += albedo * vec3(0.20, 0.27, 0.42) * SHADOW_COLOR * (1.0 - shadow) * skyMask * dayF;

    return color;
}

#endif
