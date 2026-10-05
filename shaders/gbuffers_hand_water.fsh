#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Objetos translucidos en la mano
   ========================================================================== */

#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D texture;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vShadowPos;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 albedo = tex.rgb * vColor.rgb;
    float alpha = tex.a * vColor.a;

    float dayF = getDayFactor();
    float dist = length(vViewPos);
    float shadow = getShadow(vShadowPos, vNormal, shadowLightPosition, dist);

    vec3 color = shadeSurface(albedo, lmcoord, shadow, dayF);

    float handLight = max(float(heldBlockLightValue), float(heldBlockLightValue2)) / 15.0;
    color += albedo * vec3(1.0, 0.85, 0.65) * handLight * 0.30;

    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, alpha);
}
