#version 120

/* RENDERTARGETS: 2 */

/* ==========================================================================
   Andes Shaders - Segundo paso de bloom
   Desenfoca en vertical el resultado del primer paso.
   ========================================================================== */

uniform sampler2D colortex1;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec2 dy = vec2(0.0, texel.y);

    vec3 sum = texture2D(colortex1, texcoord).rgb * 0.40;
    sum += texture2D(colortex1, texcoord + dy * 1.5).rgb * 0.24;
    sum += texture2D(colortex1, texcoord - dy * 1.5).rgb * 0.24;
    sum += texture2D(colortex1, texcoord + dy * 3.5).rgb * 0.06;
    sum += texture2D(colortex1, texcoord - dy * 3.5).rgb * 0.06;

    gl_FragData[0] = vec4(sum, 1.0);
}
