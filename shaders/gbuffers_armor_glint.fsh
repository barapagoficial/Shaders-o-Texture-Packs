#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Brillo de encantamiento
   ========================================================================== */

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    // 4 muestras del glint (el brillo se ve mejor con un poco de desenfoque)
    vec3 glint = texture2D(texture, texcoord).rgb;
    float a = texture2D(texture, texcoord).a;

    vec3 color = glint * vColor.rgb * 1.4;
    gl_FragData[0] = vec4(color, a * vColor.a);
}
