#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Entidades
   ========================================================================== */

#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D texture;
uniform vec4 entityColor;

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

    // Tinte de entidad (dano, efectos, etc.)
    albedo = mix(albedo, entityColor.rgb, entityColor.a);

    float dayF = getDayFactor();
    float dist = length(vViewPos);
    float shadow = getShadow(vShadowPos, vNormal, shadowLightPosition, dist);

    vec3 color = shadeSurface(albedo, lmcoord, shadow, dayF);
    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, alpha);
}
