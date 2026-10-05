#version 120

/* ==========================================================================
   Andes Shaders - Pase de sombras
   La misma geometria de Minecraft se dibuja desde el sol o la luna.
   La vegetacion se mece igual que en el pase normal para que su sombra
   acompanie el movimiento.
   ========================================================================== */

#include "/lib/waves.glsl"
#include "/lib/shadows.glsl"

attribute vec4 mc_Entity;
attribute vec4 at_midBlock;

uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;

varying vec4 vColor;
varying vec2 vTexCoord;

void main() {
    vec4 shadowViewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 playerPos = shadowModelViewInverse * shadowViewPos;

#if defined(SHADOWS) && (defined(WAVING_PLANTS) || defined(WAVING_LEAVES))
    vec3 worldPos = playerPos.xyz + cameraPosition;
    vec3 midOffset = at_midBlock.xyz * 0.015625; // at_midBlock viene en 1/64 de bloque
    float heightFrac = sat(-midOffset.y * 2.0 + 0.5);
    float seed = hash12(floor(worldPos.xz) + 0.5) * 6.2831;
    vec3 offset = vec3(0.0);

    #ifdef WAVING_PLANTS
    if (abs(mc_Entity.x - BLOCK_PLANTS) < 0.5) {
        offset = windOffset(worldPos, 0.10 * WAVE_STRENGTH, 1.6 * WIND_SPEED, seed) * heightFrac;
    }
    #endif

    #ifdef WAVING_LEAVES
    if (abs(mc_Entity.x - BLOCK_LEAVES) < 0.5) {
        offset = windOffset(floor(worldPos) + 0.5, 0.05 * WAVE_STRENGTH, 1.3 * WIND_SPEED, seed);
    }
    #endif

    shadowViewPos.xyz += mat3Of(shadowModelView) * offset;
#endif

    gl_Position = gl_ProjectionMatrix * shadowViewPos;

    vColor = gl_Color;
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
