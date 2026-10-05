#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Lluvia y nieve
   ========================================================================== */

#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 albedo = tex.rgb * vColor.rgb;

    // La lluvia tambien se ilumina con el lightmap (mas oscura de noche)
    vec3 lights = texture2D(lightmap, lmcoord).rgb;
    vec3 color = albedo * mix(lights, vec3(1.0), 0.25) * 0.85;

    float dist = length(vViewPos);
    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, tex.a * vColor.a);
}
