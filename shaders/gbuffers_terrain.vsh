#version 120

/* ==========================================================================
   Andes Shaders - Bloques del mundo (solid + cutout)
   Se anade el movimiento del viento a la vegetacion definida en
   block.properties (ID 100 = plantas, ID 101 = hojas).
   ========================================================================== */

#include "/lib/waves.glsl"
#include "/lib/shadows.glsl"

attribute vec4 mc_Entity;
attribute vec4 at_midBlock;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vWorldPos;
varying vec3 vShadowPos;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 playerPos = gbufferModelViewInverse * viewPos;

    vec3 worldPos = playerPos.xyz + cameraPosition;
    vec3 offset = vec3(0.0);

#if defined(WAVING_PLANTS) || defined(WAVING_LEAVES)
    // at_midBlock guarda el desplazamiento al centro del bloque en 1/64 de bloque
    vec3 midOffset = at_midBlock.xyz * 0.015625;
    float heightFrac = sat(-midOffset.y * 2.0 + 0.5); // 0 = base, 1 = parte alta
    float seed = hash12(floor(worldPos.xz) + 0.5) * 6.2831;

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

    viewPos.xyz += mat3Of(gbufferModelView) * offset;
#endif

    playerPos.xyz += offset;

    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormal = gl_NormalMatrix * gl_Normal;
    vViewPos = viewPos.xyz;
    vWorldPos = worldPos + offset;
    vShadowPos = toShadowCoords(playerPos.xyz).xyz;
}
