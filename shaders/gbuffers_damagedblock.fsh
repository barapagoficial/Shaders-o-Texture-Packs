#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Grietas de los bloques que se rompen
   ========================================================================== */

#include "/lib/fog.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 color = tex.rgb * vColor.rgb;

    float dist = length(vViewPos);
    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, tex.a * vColor.a);
}
