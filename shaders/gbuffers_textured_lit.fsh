#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Particulas
   Usan la luz del lightmap de Minecraft y la niebla.
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

    vec3 lights = texture2D(lightmap, lmcoord).rgb;
    vec3 color = albedo * lights;

    // Un poco mas de brillo para las particulas luminosas
    color += albedo * albedo * 0.25;

    float dist = length(vViewPos);
    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, tex.a * vColor.a);
}
