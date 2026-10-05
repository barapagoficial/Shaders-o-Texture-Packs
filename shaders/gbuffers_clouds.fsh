#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Nubes
   ========================================================================== */

#include "/lib/fog.glsl"

uniform sampler2D texture;
uniform vec3 sunPosition;

varying vec2 texcoord;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 color = tex.rgb * vColor.rgb;

#ifdef CLOUD_SHADING
    // Las nubes se ven mas claras del lado del sol y mas oscuras al otro lado
    float sunAmt = sat(dot(normalize(vViewPos), normalize(sunPosition)));
    color *= mix(0.88, 1.14, sunAmt);
#endif

    float dist = length(vViewPos);
    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, tex.a * vColor.a);
}
