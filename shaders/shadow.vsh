#version 120

/* ==========================================================================
   Andes Shaders - Pase de sombras
   La misma geometria de Minecraft se dibuja desde el sol o la luna.
   La vegetacion se mece sincronizada al 100% con el pase principal.
   ========================================================================== */

#include "/lib/waves.glsl"
#include "/lib/shadows.glsl"

attribute vec4 mc_Entity;
attribute vec4 at_midBlock;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;

varying vec4 vColor;
varying vec2 vTexCoord;

void main() {
    vec4 shadowViewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 playerPos = shadowModelViewInverse * shadowViewPos;

#if defined(SHADOWS) && (defined(WAVING_PLANTS) || defined(WAVING_LEAVES))
    vec3 worldPos = playerPos.xyz + cameraPosition;
    vec3 midOffset = at_midBlock.xyz * 0.015625;
    vec3 blockCenter = worldPos + midOffset;
    vec3 blockCoord = floor(blockCenter + 0.001) + 0.5;
    vec3 offset = vec3(0.0);

    #ifdef WAVING_PLANTS
    if (abs(mc_Entity.x - BLOCK_PLANTS) < 0.5) {
        float heightFrac = sat(-midOffset.y * 2.0 + 0.5);
        offset = plantWindOffset(worldPos, blockCoord, heightFrac, 0.08 * WAVE_STRENGTH, 1.2 * WIND_SPEED);
    }
    #endif

    #ifdef WAVING_LEAVES
    if (abs(mc_Entity.x - BLOCK_LEAVES) < 0.5) {
        offset = leavesWindOffset(blockCoord, 0.035 * WAVE_STRENGTH, 0.85 * WIND_SPEED);
    }
    #endif

    shadowViewPos.xyz += mat3Of(shadowModelView) * offset;
#endif

    gl_Position = gl_ProjectionMatrix * shadowViewPos;

    vColor = gl_Color;
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
