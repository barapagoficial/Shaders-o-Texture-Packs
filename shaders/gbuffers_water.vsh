#version 120

/* ==========================================================================
   Andes Shaders - Bloques translucidos (agua, cristal, hielo, lava)
   Olas fluidas y dinamicas en la superficie del agua.
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
varying float vIsFluid;
varying float vIsLava;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 playerPos = gbufferModelViewInverse * viewPos;
    vec3 worldPos = playerPos.xyz + cameraPosition;

    vec3 offset = vec3(0.0);

    // Identificacion robusta de fluidos (por ID 102/103 y por atributo mc_Entity.y)
    float isLava = (abs(mc_Entity.x - BLOCK_LAVA) < 0.5) ? 1.0 : 0.0;
    float isFluid = (abs(mc_Entity.x - BLOCK_WATER) < 0.5 || (mc_Entity.y > 0.5 && isLava < 0.5)) ? 1.0 : 0.0;

#ifdef WATER_WAVES
    if (isFluid > 0.5) {
        // topFrac asegura que solo la superficie se ondula, no el lecho del rio
        vec3 midOffset = at_midBlock.xyz * 0.015625;
        float topFrac = sat(-midOffset.y * 2.0 + 0.5);
        offset = vec3(0.0, waterWaveHeight(worldPos, 0.07 * WATER_WAVE_HEIGHT) * topFrac, 0.0);
        viewPos.xyz += mat3Of(gbufferModelView) * offset;
        playerPos.xyz += offset;
    }
#endif

    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormal = gl_NormalMatrix * gl_Normal;
    vViewPos = viewPos.xyz;
    vWorldPos = worldPos + offset;

    vec3 normalPlayer = mat3Of(gbufferModelViewInverse) * vNormal;
    float normLen = dot(normalPlayer, normalPlayer);
    if (normLen > 0.0001) normalPlayer *= inversesqrt(normLen);
    else normalPlayer = vec3(0.0, 1.0, 0.0);

    vShadowPos = toShadowCoordsBiased(playerPos.xyz, normalPlayer).xyz;
    vIsFluid = isFluid;
    vIsLava = isLava;
}
