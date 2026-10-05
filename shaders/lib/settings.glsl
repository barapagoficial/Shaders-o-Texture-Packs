/* ==========================================================================
   Andes Shaders - Ajustes compartidos
   Este archivo se incluye desde TODOS los programas del pack.
   Las constantes de aqui abajo las lee Iris/OptiFine: si llevan una lista de
   valores entre corchetes tambien aparecen en el menu de opciones del juego.
   ========================================================================== */
#ifndef ANDES_SETTINGS_GLSL
#define ANDES_SETTINGS_GLSL

/* --- Resolucion del mapa de sombras --------------------------------------- */
const int shadowMapResolution = 2048; // [1024 2048 3072 4096] Resolucion del mapa de sombras
const float shadowDistance = 128.0; // [64.0 96.0 128.0 160.0 192.0] Distancia maxima de las sombras (bloques)

/* --- Parametros del pipeline de sombras ----------------------------------- */
const float shadowIntervalSize = 2.0;
const bool shadowHardwareFiltering = true;

/* --- Valores derivados ---------------------------------------------------- */
const float SHADOW_TEXEL_SIZE = 1.0 / float(shadowMapResolution);
const float SHADOW_BIAS_BASE  = 0.0007;
const float SHADOW_BIAS_SLOPE = 0.0028;

/* --- IDs de bloque (deben coincidir con block.properties) ----------------- */
const float BLOCK_PLANTS = 100.0;
const float BLOCK_LEAVES = 101.0;
const float BLOCK_LAVA   = 102.0;

#endif
