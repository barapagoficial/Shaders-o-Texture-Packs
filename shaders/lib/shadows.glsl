/* ==========================================================================
   Andes Shaders - Coordenadas del mapa de sombras (solo lo que necesitan
   los vertex shaders: matrices y conversion de espacio).
   ========================================================================== */
#ifndef ANDES_SHADOWS_GLSL
#define ANDES_SHADOWS_GLSL

#include "/lib/common.glsl"

#ifdef SHADOWS
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
#endif

/* De espacio de jugador (relativo a la camara) a coordenadas del mapa de sombras */
vec4 toShadowCoords(vec3 playerPos) {
#ifdef SHADOWS
    vec4 clip = shadowProjection * (shadowModelView * vec4(playerPos, 1.0));
    float w = (abs(clip.w) < 0.00001) ? 1.0 : clip.w;
    clip.xyz = clip.xyz / w;
    return vec4(clip.xyz * 0.5 + 0.5, w);
#else
    return vec4(0.0);
#endif
}

/* Version con desplazamiento segun la normal para evitar acné en superficies */
vec4 toShadowCoordsBiased(vec3 playerPos, vec3 normalPlayer) {
#ifdef SHADOWS
    vec3 biasedPos = playerPos + normalPlayer * 0.035;
    vec4 clip = shadowProjection * (shadowModelView * vec4(biasedPos, 1.0));
    float w = (abs(clip.w) < 0.00001) ? 1.0 : clip.w;
    clip.xyz = clip.xyz / w;
    return vec4(clip.xyz * 0.5 + 0.5, w);
#else
    return vec4(0.0);
#endif
}

#endif
