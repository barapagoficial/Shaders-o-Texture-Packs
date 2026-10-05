#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Bloques del mundo
   Iluminacion del lightmap de Minecraft + sombras dinamicas + niebla.
   ========================================================================== */

#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D texture;
uniform float wetness;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vWorldPos;
varying vec3 vShadowPos;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    float alpha = tex.a * vColor.a;
    if (alpha < alphaTestRef) discard;

    vec3 albedo = tex.rgb * vColor.rgb;

    // La lluvia oscurece un poco el terreno
    albedo *= 1.0 - 0.15 * wetness;

    float dayF = getDayFactor();
    float dist = length(vViewPos);
    float shadow = getShadow(vShadowPos, vNormal, shadowLightPosition, dist);

    vec3 color = shadeSurface(albedo, lmcoord, shadow, dayF);

    // Brillo del suelo mojado por la lluvia
    if (wetness > 0.02) {
        vec3 viewDir = normalize(vViewPos);
        vec3 halfDir = normalize(normalize(shadowLightPosition) - viewDir);
        float spec = pow(sat(dot(normalize(vNormal), halfDir)), 60.0);
        color += vec3(1.0, 0.95, 0.85) * spec * wetness * dayF * shadow * 0.35;
    }

    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, 1.0);
}
