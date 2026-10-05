#version 120

/* RENDERTARGETS: 0 */

/* ==========================================================================
   Andes Shaders - Pase de sombras
   Solo importan la profundidad (shadowtex0/shadowtex1) y descartar las
   partes transparentes de las texturas: asi las hojas y la hierba proyectan
   la forma real de su textura y no un cuadrado opaco.
   ========================================================================== */

uniform sampler2D texture;
uniform float alphaTestRef;

varying vec4 vColor;
varying vec2 vTexCoord;

void main() {
    vec4 tex = texture2D(texture, vTexCoord);
    if (tex.a * vColor.a < alphaTestRef) discard;

    gl_FragData[0] = vec4(1.0);
}
