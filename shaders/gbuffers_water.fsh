#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Agua y bloques translucidos
   Agua cristalina con olas realistas, reflejos Fresnel dependientes de la
   hora del dia, brillos solares y lunares, y transparencia limpia.
   La lava (ID 102) se dibuja incandescente con luz propia.
   El cristal y el hielo usan la iluminacion limpia normal.
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

    vec3 normal = vNormal;
    float lenSq = dot(normal, normal);
    if (lenSq > 0.0001) normal *= inversesqrt(lenSq);
    else normal = vec3(0.0, 1.0, 0.0);

    float dayF = getDayFactor();
    float dist = length(vViewPos);

    // --- 1. Lava incandescente (emite su propia luz ardiente) ---
    if (vIsLava > 0.5) {
        vec3 lights = texture2D(lightmap, lmcoord).rgb;
        vec3 lavaCore = albedo * vec3(1.35, 1.05, 0.75);
        vec3 lavaColor = mix(lavaCore, lavaCore * lights, 0.25);
        lavaColor += lavaCore * lavaCore * 0.40; // resplandor caliente
        lavaColor = applyFog(lavaColor, dist);
        gl_FragData[0] = vec4(lavaColor, alpha);
        return;
    }

    // --- 2. Superficie de agua y olas ---
    if (vIsFluid > 0.5) {
#ifdef WATER_WAVES
        vec3 nWorld = waterSurfaceNormal(vWorldPos, 0.07 * WATER_WAVE_HEIGHT);
        normal = normalize(mat3Of(gbufferModelView) * nWorld);
#endif
        // Tinte cristalino que embellece el agua del bioma sin volverla un lodo oscuro
        albedo = mix(albedo, vec3(0.12, 0.44, 0.64), 0.35);
    }

    float shadow = getShadow(vShadowPos, normal, shadowLightPosition, dist);
    vec3 color = shadeSurface(albedo, lmcoord, shadow, dayF, dist);

    // --- 3. Reflejos y brillos especulares en el agua ---
    if (vIsFluid > 0.5) {
        vec3 viewDir = normalize(vViewPos);
        float cosT = sat(dot(normal, -viewDir));
        float fresnel = 0.035 + 0.965 * pow(1.0 - cosT, 5.0);

        // Color del cielo reflejado segun la hora del dia
        vec3 skyReflDay = mix(skyColor, fogColor, 0.30);
        vec3 skyReflNight = vec3(0.06, 0.09, 0.17) * NIGHT_BRIGHTNESS;
        vec3 reflSky = mix(skyReflNight, skyReflDay, dayF);

        // Resplandor dorado en el agua durante amaneceres y atardeceres
        if (dayF > 0.05 && dayF < 0.90) {
            vec3 reflVector = reflect(viewDir, normal);
            float sunsetAlignment = sat(dot(reflVector, normalize(shadowLightPosition)));
            float sunsetFactor = 1.0 - abs(dayF - 0.45) * 2.2;
            reflSky += vec3(1.0, 0.48, 0.18) * pow(sunsetAlignment, 6.0) * sat(sunsetFactor) * 0.8;
        }

        color = mix(color, reflSky, fresnel * sat(WATER_REFLECTIVITY * 0.85));

        // Reflejo especular del sol (dia) y de la luna (noche)
        vec3 lightDir = normalize(shadowLightPosition);
        vec3 refl = reflect(viewDir, normal);
        float spec = pow(sat(dot(refl, lightDir)), 140.0);

        vec3 sunSpec = vec3(1.20, 1.10, 0.92) * 2.5;
        vec3 moonSpec = vec3(0.70, 0.82, 1.05) * (0.85 * NIGHT_BRIGHTNESS);
        vec3 specColor = mix(moonSpec, sunSpec, dayF);

        color += specColor * spec * shadow * sat(WATER_REFLECTIVITY);

        // Transparencia cristalina: transparente al mirar hacia abajo, reflectante en angulos rasantes
        alpha = mix(0.52, 0.88, fresnel);
    }

    color = applyFog(color, dist);

    gl_FragData[0] = vec4(color, alpha);
}
