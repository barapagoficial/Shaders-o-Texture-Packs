#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Mano
   ========================================================================== */

#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vShadowPos;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    float alpha = tex.a * vColor.a;
    if (alpha < alphaTestRef) discard;

    vec3 albedo = tex.rgb * vColor.rgb;

    float dayF = getDayFactor();
    float dist = length(vViewPos);
    float shadow = getShadow(vShadowPos, vNormal, shadowLightPosition, dist);

    vec3 color = shadeSurface(albedo, lmcoord, shadow, dayF, dist);

    // Resplandor directo sobre la propia mano si sostiene un objeto luminoso
    float handLight = max(float(heldBlockLightValue), float(heldBlockLightValue2)) / 15.0;
    color += albedo * vec3(1.15, 0.82, 0.45) * handLight * 0.35;

    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, alpha);
}
