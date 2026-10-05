#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Particulas
   Usan la iluminacion ambiental, tinte calido de antorchas y niebla.
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
    float dayF = getDayFactor();
    lights *= 1.0 + (1.0 - dayF) * (NIGHT_BRIGHTNESS - 1.0);

#ifdef BLOCKLIGHT_TINT
    lights *= mix(vec3(1.0), vec3(1.15, 0.85, 0.65), sat(lmcoord.x * 1.5));
#endif

    vec3 color = albedo * lights;
    // Realce para particulas luminosas (fuego, antorchas)
    color += albedo * albedo * 0.35;

    float dist = length(vViewPos);
    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, tex.a * vColor.a);
}
