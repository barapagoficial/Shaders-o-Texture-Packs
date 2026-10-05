#version 120

/* RENDERTARGETS: 1 */

/* ==========================================================================
   Andes Shaders - Primer paso de bloom
   Extrae las zonas brillantes de la escena y las desenfoca en horizontal.
   ========================================================================== */

#include "/lib/common.glsl"

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

/* Umbral suave: solo las zonas claras contribuyen al resplandor */
vec3 brightPass(vec3 c) {
    float l = luma(c);
    float knee = 0.55;
    float soft = sat(l - 0.70 + knee);
    soft = soft * soft / (4.0 * knee + 0.0001);
    float w = max(soft, l - 0.70) / max(l, 0.0001);
    return c * w;
}

void main() {
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec2 dx = vec2(texel.x, 0.0);

    vec3 sum = brightPass(texture2D(colortex0, texcoord).rgb) * 0.40;
    sum += brightPass(texture2D(colortex0, texcoord + dx * 1.5).rgb) * 0.24;
    sum += brightPass(texture2D(colortex0, texcoord - dx * 1.5).rgb) * 0.24;
    sum += brightPass(texture2D(colortex0, texcoord + dx * 3.5).rgb) * 0.06;
    sum += brightPass(texture2D(colortex0, texcoord - dx * 3.5).rgb) * 0.06;

    gl_FragData[0] = vec4(sum, 1.0);
}
