/* ==========================================================================
   Andes Shaders - Ajustes y opciones compartidos
   Este archivo se incluye desde TODOS los programas del pack (a traves de
   /lib/common.glsl).

   IMPORTANTE: Iris/OptiFine leen las opciones del menu "Shader Pack Settings"
   UNICAMENTE de los archivos de shader (.vsh/.fsh y los archivos que estos
   incluyen).  Las opciones escritas en "shaders.properties" NO llegan nunca al
   codigo GLSL, por eso se declaran aqui, con este formato:

     - Booleana: una directiva define con el nombre y una descripcion despues
       de "//" (el #ifdef/#ifndef correspondiente debe existir en el pack).
     - Con valores: la directiva define, un valor por defecto y, en el
       comentario, la lista de valores permitidos entre corchetes.
     - Los nombres "const" que reconoce Iris (shadowMapResolution y
       shadowDistance) se declaran como const y tambien llevan su lista.

   Cualquier linea que empiece por "#define" o "const" se lee como una posible
   opcion, asi que este comentario evita escribirlas literalmente.
   ========================================================================== */
#ifndef ANDES_SETTINGS_GLSL
#define ANDES_SETTINGS_GLSL

/* ================================ CIELO =================================== */
#define CUSTOM_SKY // Cielo propio: degradado, resplandor solar, puesta de sol y estrellas
#define SUN_GLOW 1.0 // [0.0 0.5 1.0 1.5 2.0] Resplandor alrededor del sol y de la luna
#define STARS 1.0 // [0.0 0.5 1.0 1.5 2.0] Brillo de las estrellas
#define HORIZON_FOG 1.0 // [0.5 0.75 1.0 1.5 2.0] Densidad de la neblina del horizonte
#define CLOUD_SHADING // Sombrea las nubes segun la hora del dia

/* ============================= ILUMINACION ================================ */
#define SHADOWS // Sombras dinamicas con filtrado suave
#define SHADOW_SOFTNESS 1.0 // [0.5 1.0 1.5 2.0 3.0] Suavizado del borde de las sombras
#define SHADOW_COLOR 0.65 // [0.0 0.25 0.5 0.65 0.85 1.0] Rebote frio del cielo dentro de las sombras
#define NIGHT_BRIGHTNESS 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0] Brillo de la luz de la luna por la noche
#define BLOCKLIGHT_TINT // Tinte calido para antorchas y bloques luminosos

/* ================================== AGUA ================================== */
#define WATER_WAVES // Olas en la superficie del agua
#define WATER_WAVE_HEIGHT 1.0 // [0.0 0.5 1.0 1.5 2.0] Altura de las olas
#define WATER_REFLECTIVITY 1.0 // [0.0 0.5 1.0 1.5 2.0] Reflejo del cielo y brillo del sol en el agua

/* =============================== VEGETACION =============================== */
#define WAVING_PLANTS // Balanceo de hierba, flores, cultivos y similares
#define WAVING_LEAVES // Balanceo suave de las hojas
#define WAVE_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0] Fuerza del viento
#define WIND_SPEED 1.0 // [0.25 0.5 1.0 1.5 2.0] Velocidad del viento

/* ============================= POST-PROCESADO ============================= */
#define BLOOM // Resplandor alrededor de las luces y superficies brillantes
#define BLOOM_STRENGTH 0.5 // [0.0 0.25 0.5 0.75 1.0] Intensidad del resplandor
#define TONEMAP 1 // [0 1 2] Mapeo de tonos: 0 = ninguno, 1 = suave, 2 = filmico
#define EXPOSURE 1.0 // [0.7 0.85 1.0 1.15 1.3] Exposicion general de la imagen
#define SATURATION 1.05 // [0.8 0.9 1.0 1.05 1.15 1.3] Saturacion del color
#define CONTRAST 1.03 // [0.9 0.95 1.0 1.03 1.1 1.2] Contraste
#define VIGNETTE 0.3 // [0.0 0.15 0.3 0.45 0.6] Vineta (oscurecimiento de las esquinas)
#define FXAA // Suavizado de bordes (FXAA)
#define UNDERWATER_TINT // Tinte azulado al estar bajo el agua

/* ============================ MAPA DE SOMBRAS ============================= */
/* Estos dos "const" los reconoce directamente Iris/OptiFine y cambian el
   tamano real del mapa de sombras y su distancia maxima. */
const int shadowMapResolution = 2048; // [1024 2048 3072 4096] Resolucion del mapa de sombras
const float shadowDistance = 128.0; // [64.0 96.0 128.0 160.0 192.0] Distancia maxima de las sombras (bloques)

/* ========================= PARAMETROS DEL PIPELINE ======================== */
const float shadowIntervalSize = 2.0;
const bool shadowHardwareFiltering = false;

/* --- Valores derivados ---------------------------------------------------- */
const float SHADOW_TEXEL_SIZE = 1.0 / float(shadowMapResolution);
const float SHADOW_BIAS_BASE  = 0.0004;
const float SHADOW_BIAS_SLOPE = 0.0016;

/* --- IDs de bloque (deben coincidir con block.properties) ----------------- */
const float BLOCK_PLANTS = 100.0;
const float BLOCK_LEAVES = 101.0;
const float BLOCK_LAVA   = 102.0;
const float BLOCK_WATER  = 103.0;

#endif
