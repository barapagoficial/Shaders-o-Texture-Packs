#version 120

/* ==========================================================================
   Andes Shaders - Bloques translucidos (agua, cristal, hielo...)
   Las olas solo afectan a los fluidos y solo a su superficie.
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

    // mc_Entity.y vale 1.0 para fluidos (agua, lava) y -1.0 para el resto
    float isFluid = (mc_Entity.y > 0.5) ? 1.0 : 0.0;
    float isLava = (abs(mc_Entity.x - BLOCK_LAVA) < 0.5) ? 1.0 : 0.0;
    isFluid *= 1.0 - isLava; // la lava tiene su propio aspecto

#ifdef WATER_WAVES
    if (isFluid > 0.5) {
        vec3 midOffset = at_midBlock.xyz * 0.015625;
        float topFrac = sat(-midOffset.y * 2.0 + 0.5);
        offset = vec3(0.0, waterWave(worldPos, 0.10 * WATER_WAVE_HEIGHT) * topFrac, 0.0);
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
    vShadowPos = toShadowCoords(playerPos.xyz).xyz;
    vIsFluid = isFluid;
    vIsLava = isLava;
}
