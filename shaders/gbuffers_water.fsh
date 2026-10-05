#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Agua y bloques translucidos
   El agua tiene olas, reflejo del cielo, brillo del sol, sombras y niebla.
   La lava (ID 102 en block.properties) se dibuja incandescente.
   El cristal y el hielo usan la iluminacion normal.
   ========================================================================== */

#include "/lib/waves.glsl"
#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D texture;
uniform vec3 skyColor;
uniform mat4 gbufferModelView;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vWorldPos;
varying vec3 vShadowPos;
varying float vIsFluid;
varying float vIsLava;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 albedo = tex.rgb * vColor.rgb;
    float alpha = tex.a * vColor.a;

    vec3 normal = normalize(vNormal);
    float dayF = getDayFactor();
    float dist = length(vViewPos);
    float shadow = getShadow(vShadowPos, normal, shadowLightPosition, dist);

    if (vIsFluid > 0.5) {
#ifdef WATER_WAVES
        // La superficie del agua ondula: usamos la normal de las olas
        vec3 nWorld = waterNormal(vWorldPos, 0.10 * WATER_WAVE_HEIGHT);
        normal = normalize(mat3Of(gbufferModelView) * nWorld);
#endif
        // Agua profunda: color mas oscuro y azulado
        albedo *= vec3(0.35, 0.55, 0.75);
        shadow = getShadow(vShadowPos, normal, shadowLightPosition, dist);
    }

    vec3 color = shadeSurface(albedo, lmcoord, shadow, dayF);

    // --- Lava: emite luz propia ---
    if (vIsLava > 0.5) {
        vec3 lights = texture2D(lightmap, lmcoord).rgb;
        vec3 lava = albedo * vec3(1.25, 1.00, 0.85);
        color = lava * mix(vec3(0.85), lights, 0.35);
        color += lava * lava * 0.35; // pequeno halo
        color = applyFog(color, dist);
        gl_FragData[0] = vec4(color, alpha);
        return;
    }

    // --- Agua: reflejo del cielo y brillo del sol/luna ---
    if (vIsFluid > 0.5) {
        vec3 viewDir = normalize(vViewPos);
        float cosT = sat(dot(normal, -viewDir));
        float fresnel = 0.02 + 0.98 * pow(1.0 - cosT, 5.0);

        vec3 reflColor = mix(skyColor, fogColor, 0.25);
        reflColor *= 0.55 + 0.45 * dayF;

        color = mix(color, reflColor, fresnel * sat(WATER_REFLECTIVITY * 0.9));

        vec3 lightDir = normalize(shadowLightPosition);
        vec3 refl = reflect(viewDir, normal);
        float spec = pow(sat(dot(refl, lightDir)), 220.0);
        vec3 specColor = mix(vec3(1.0, 0.96, 0.88), vec3(0.75, 0.82, 1.0), 1.0 - dayF);
        color += specColor * spec * dayF * shadow * sat(WATER_REFLECTIVITY) * 2.5;

        // El agua es un poco mas transparente al mirarla de frente
        alpha = mix(alpha, alpha * 0.85, cosT);
    }

    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, alpha);
}
