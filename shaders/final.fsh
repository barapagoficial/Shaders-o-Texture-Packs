#version 120

/* Sin RENDERTARGETS: este programa se dibuja directamente en la pantalla */

/* ==========================================================================
   Andes Shaders - Paso final
   Antialiasing (FXAA), resplandor (bloom), mapeo de tonos, color, vineta y
   tinte bajo el agua.
   ========================================================================== */

#include "/lib/common.glsl"

uniform sampler2D colortex0;
#ifdef BLOOM
uniform sampler2D colortex2;
#endif

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform int isEyeInWater;

varying vec2 texcoord;

#ifdef FXAA
/* FXAA 3.11 (version compacta) */
vec3 fxaa(sampler2D tex, vec2 uv, vec2 texel) {
    vec3 rgbM  = texture2D(tex, uv).rgb;
    vec3 rgbNW = texture2D(tex, uv + vec2(-1.0, -1.0) * texel).rgb;
    vec3 rgbNE = texture2D(tex, uv + vec2( 1.0, -1.0) * texel).rgb;
    vec3 rgbSW = texture2D(tex, uv + vec2(-1.0,  1.0) * texel).rgb;
    vec3 rgbSE = texture2D(tex, uv + vec2( 1.0,  1.0) * texel).rgb;

    float lumaM  = luma(rgbM);
    float lumaNW = luma(rgbNW);
    float lumaNE = luma(rgbNE);
    float lumaSW = luma(rgbSW);
    float lumaSE = luma(rgbSE);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * 0.25 * 0.125, 1.0 / 128.0);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(8.0), max(vec2(-8.0), dir * rcpDirMin)) * texel;

    vec3 rgbA = 0.5 * (texture2D(tex, uv + dir * (1.0 / 3.0 - 0.5)).rgb +
                       texture2D(tex, uv + dir * (2.0 / 3.0 - 0.5)).rgb);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (texture2D(tex, uv + dir * -0.5).rgb +
                                     texture2D(tex, uv + dir *  0.5).rgb);

    float lumaB = luma(rgbB);
    return (lumaB < lumaMin || lumaB > lumaMax) ? rgbA : rgbB;
}
#endif

void main() {
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);

#ifdef FXAA
    vec3 color = fxaa(colortex0, texcoord, texel);
#else
    vec3 color = texture2D(colortex0, texcoord).rgb;
#endif

#ifdef BLOOM
    color += texture2D(colortex2, texcoord).rgb * (BLOOM_STRENGTH * 1.8);
#endif

    color *= EXPOSURE;

#if TONEMAP == 1
    color = tonemapSoft(color);
#elif TONEMAP == 2
    color = tonemapFilmic(color);
#endif

#ifdef UNDERWATER_TINT
    if (isEyeInWater == 1) {
        color = mix(color, color * vec3(0.62, 0.86, 1.0) + vec3(0.0, 0.01, 0.04), 0.55);
    }
#endif

    color = applyGrading(color);
    color *= vignetteFactor(texcoord, aspectRatio);

    gl_FragColor = vec4(color, 1.0);
}
