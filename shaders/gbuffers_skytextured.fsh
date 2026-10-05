#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Sol y luna
   Se tinen ligeramente: el sol mas calido y la luna mas fria.
   ========================================================================== */

#include "/lib/common.glsl"

uniform sampler2D texture;
uniform int renderStage;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 color = tex.rgb * vColor.rgb;

#ifdef CUSTOM_SKY
    if (renderStage == MC_RENDER_STAGE_SUN) {
        color *= vec3(1.06, 1.00, 0.88);
    } else if (renderStage == MC_RENDER_STAGE_MOON) {
        color *= vec3(0.88, 0.94, 1.08);
    }
#endif

    gl_FragData[0] = vec4(color, tex.a * vColor.a);
}
