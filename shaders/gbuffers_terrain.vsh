#version 120

/* ==========================================================================
   Andes Shaders - Bloques del mundo (solid + cutout)
   Vegetacion mecida por el viento de forma suave y organica.
   ID 100 = plantas (base anclada), ID 101 = hojas (bloque entero sincronizado).
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
    // at_midBlock apunta al centro del bloque: esto garantiza que todos
    // los vertices del bloque compartan la misma referencia espacial exacta.
    vec3 midOffset = at_midBlock.xyz * 0.015625;
    vec3 blockCenter = worldPos + midOffset;
    vec3 blockCoord = floor(blockCenter + 0.001) + 0.5;

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

    viewPos.xyz += mat3Of(gbufferModelView) * offset;
    playerPos.xyz += offset;
#endif

    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormal = gl_NormalMatrix * gl_Normal;
    vViewPos = viewPos.xyz;
    vWorldPos = worldPos + offset;

    // Normal en espacio de jugador para sesgo suave contra acné en sombras
    vec3 normalPlayer = mat3Of(gbufferModelViewInverse) * vNormal;
    float normLen = dot(normalPlayer, normalPlayer);
    if (normLen > 0.0001) normalPlayer *= inversesqrt(normLen);
    else normalPlayer = vec3(0.0, 1.0, 0.0);

    vShadowPos = toShadowCoordsBiased(playerPos.xyz, normalPlayer).xyz;
}
