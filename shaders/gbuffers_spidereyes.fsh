#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Ojos brillantes
   ========================================================================== */

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 color = tex.rgb * vColor.rgb * 1.15;
    gl_FragData[0] = vec4(color, tex.a * vColor.a);
}
