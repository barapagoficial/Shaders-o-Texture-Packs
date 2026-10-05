#version 120

/* ==========================================================================
   Andes Shaders - Objetos translucidos en la mano
   ========================================================================== */

#include "/lib/shadows.glsl"

uniform mat4 gbufferModelViewInverse;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vShadowPos;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 playerPos = gbufferModelViewInverse * viewPos;

    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormal = gl_NormalMatrix * gl_Normal;
    vViewPos = viewPos.xyz;
    vShadowPos = toShadowCoords(playerPos.xyz).xyz;
}
