# Andes Shaders 🌄

Pack de **shaders para Minecraft Java 1.21.11** (formato OptiFine/Iris) con sombras
dinámicas, agua con olas, viento en la vegetación, cielo propio, niebla, bloom y
corrección de color.

Está pensado para funcionar con **Iris** (Fabric, NeoForge o Quilt) junto a **Sodium**,
que es la forma actual de usar shaders en 1.21.11.

---

## ✨ Características

| Efecto | Detalle |
|---|---|
| **Sombras dinámicas** | Mapa de sombras de 1024 a 4096 px, filtrado suave (PCF 4 muestras), sombras que se desvanecen con la distancia, bias según el ángulo de la superficie y descarte de las partes transparentes de las texturas (las hojas y la hierba proyectan su forma real). |
| **Cielo propio** | Degradado entre el color del horizonte y el cenit, banda de puesta de sol, resplandor del sol y de la luna y estrellas generadas por procedimiento. |
| **Agua** | Olas animadas en la superficie, normal de las olas para el brillo del sol, reflejo del cielo por Fresnel y niebla. |
| **Lava** | Se dibuja incandescente, sin reflejos ni tinte de agua. |
| **Viento** | Balanceo de hierba, flores, cultivos y enredaderas (por vértice) y de las hojas (movimiento rígido del bloque). La sombra de las plantas se mueve con ellas. |
| **Iluminación** | Lightmap de Minecraft + luz fría de rebote del cielo dentro de las sombras, tinte cálido para antorchas, luz de la mano con antorchas/linternas y brillo del suelo mojado con la lluvia. |
| **Post-procesado** | Bloom (2 pasadas), mapeo de tonos (suave o fílmico), exposición, saturación, contraste, viñeta, FXAA y tinte bajo el agua. |
| **Rendimiento** | 5 perfiles listos para usar y opciones para apagar sombras, olas, viento, bloom y FXAA. Si apagas las sombras, el pase de sombras ni se ejecuta; sin bloom, las dos pasadas de desenfoque tampoco. |

---

## 📋 Requisitos

- Minecraft Java **1.21.11** (también funciona en 1.21.x recientes).
- **Iris 1.10.0 o superior** para 1.21.11 (Fabric, NeoForge o Quilt).
- **Sodium** (obligatorio con Iris en versiones modernas).
- GPU con OpenGL 3.3 o superior.
- El pack **no usa** compute shaders ni SSBO, así que también funciona en macOS.

> El pack está escrito en el formato clásico de OptiFine/Iris (`gbuffers_*`, `shadow`,
> `composite*`, `final`), que Iris sigue soportando en 1.21.11.

---

## 🚀 Instalación

1. Instala **Iris + Sodium** en tu instalación de 1.21.11.
2. Descarga el pack ya empaquetado: **[`releases/Andes-Shaders-v1.0.0.zip`](releases/Andes-Shaders-v1.0.0.zip)**
   (o créalo tú mismo con `python3 tools/build_pack.py`).
3. Copia el `.zip` en la carpeta `shaderpacks` de tu Minecraft
   (*Opciones → Vídeo → Shader Packs → Abrir carpeta de shaders*).
4. En el juego: *Opciones → Vídeo → Shader Packs* y elige **Andes Shaders**.
5. Ajusta las opciones en **Shader Pack Settings** (incluye perfiles).

---

## ⚙️ Opciones

Las opciones se definen en [`shaders/shaders.properties`](shaders/shaders.properties)
y aparecen en el menú *Shader Pack Settings*.

### Perfiles

| Perfil | Qué activa |
|---|---|
| **PATATA** | Sin sombras, sin bloom, sin olas, sin viento, sin FXAA, sombras a 1024 y 64 bloques. |
| **RÁPIDO** | Como PATATA pero con viento en las plantas y viñeta suave. |
| **EQUILIBRADO** | Recomendado: sombras 2048, bloom, FXAA, olas y viento. |
| **ALTO** | Sombras 3072, 160 bloques, todo lo anterior. |
| **ULTRA** | Sombras 4096, 192 bloques, mapeo de tonos fílmico y bloom fuerte. |

### Lista completa

| Opción | Valores | Descripción |
|---|---|---|
| `CUSTOM_SKY` | sí/no | Cielo propio con degradado, resplandor y estrellas. |
| `SUN_GLOW` | 0.0 – 2.0 | Resplandor del sol y de la luna. |
| `STARS` | 0.0 – 2.0 | Brillo de las estrellas. |
| `HORIZON_FOG` | 0.5 – 2.0 | Densidad de la neblina del horizonte. |
| `CLOUD_SHADING` | sí/no | Sombreado de las nubes según la posición del sol. |
| `SHADOWS` | sí/no | Sombras dinámicas. |
| `SHADOW_SOFTNESS` | 0.5 – 3.0 | Radio del filtrado de bordes. |
| `SHADOW_COLOR` | 0.0 – 1.0 | Luz fría (rebote del cielo) dentro de las sombras. |
| `NIGHT_BRIGHTNESS` | 0.5 – 2.0 | Brillo de la luz de la luna. |
| `BLOCKLIGHT_TINT` | sí/no | Tinte cálido para antorchas y bloques luminosos. |
| `shadowMapResolution` | 1024 / 2048 / 3072 / 4096 | Resolución del mapa de sombras. |
| `shadowDistance` | 64 – 192 | Distancia de las sombras en bloques. |
| `WATER_WAVES` | sí/no | Olas en el agua. |
| `WATER_WAVE_HEIGHT` | 0.0 – 2.0 | Altura de las olas. |
| `WATER_REFLECTIVITY` | 0.0 – 2.0 | Reflejo del cielo y brillo del sol en el agua. |
| `WAVING_PLANTS` | sí/no | Viento en hierba, flores, cultivos y enredaderas. |
| `WAVING_LEAVES` | sí/no | Viento en las hojas. |
| `WAVE_STRENGTH` | 0.0 – 2.0 | Fuerza del viento. |
| `WIND_SPEED` | 0.25 – 2.0 | Velocidad del viento. |
| `BLOOM` | sí/no | Resplandor de luces y superficies brillantes. |
| `BLOOM_STRENGTH` | 0.0 – 1.0 | Intensidad del resplandor. |
| `TONEMAP` | 0 / 1 / 2 | Mapeo de tonos: ninguno, suave o fílmico. |
| `EXPOSURE` | 0.7 – 1.3 | Brillo general. |
| `SATURATION` | 0.8 – 1.3 | Saturación del color. |
| `CONTRAST` | 0.9 – 1.2 | Contraste. |
| `VIGNETTE` | 0.0 – 0.6 | Oscurecimiento de las esquinas. |
| `FXAA` | sí/no | Antialiasing. |
| `UNDERWATER_TINT` | sí/no | Tinte azulado bajo el agua. |

El menú está traducido al español y al inglés (`shaders/lang/es_es.lang` y
`shaders/lang/en_us.lang`).

---

## 📁 Estructura del repositorio

```
shaders/                  <- el pack (esta carpeta va en la raíz del .zip)
├── shaders.properties    <- opciones, perfiles, menús y ajustes del pipeline
├── block.properties      <- IDs de bloque para el viento y la lava
├── lang/                 <- traducciones de las opciones
├── lib/                  <- código compartido
│   ├── settings.glsl     <- constantes del pipeline (resolución de sombras, etc.)
│   ├── common.glsl       <- utilidades (ruido, mapeo de tonos, color, viñeta)
│   ├── fog.glsl          <- niebla
│   ├── lighting.glsl     <- lightmap, sombras y sombreado de superficies
│   ├── shadows.glsl      <- coordenadas del mapa de sombras
│   └── waves.glsl        <- viento y olas
├── gbuffers_*.vsh/.fsh   <- terreno, agua, entidades, mano, cielo, partículas...
├── shadow.vsh/.fsh       <- pase de sombras
├── composite*.vsh/.fsh   <- bloom (2 pasadas)
└── final.vsh/.fsh        <- FXAA, bloom, tonos, color y viñeta
tools/
├── validate_shaders.py   <- valida el pack sin abrir Minecraft
└── build_pack.py         <- crea releases/Andes-Shaders-vX.Y.Z.zip
releases/                 <- packs empaquetados listos para shaderpacks/
```

---

## ✅ Validación (sin abrir Minecraft)

`tools/validate_shaders.py` resuelve los `#include` como hace Iris, inyecta los
`#define` de las opciones y **compila los 46 programas con glslang** en cuatro
combinaciones de opciones (por defecto, todo al máximo, todo al mínimo y perfil
patata). Además revisa:

- que los `uniform` usados existan en la API de Iris/OptiFine;
- que los atributos (`mc_Entity`, `at_midBlock`) se usen solo donde están permitidos;
- que cada `.fsh` que escribe color declare `/* RENDERTARGETS: N */`;
- que los `varying` del `.fsh` estén declarados en su `.vsh`;
- que las opciones del menú, los sliders y los perfiles existan de verdad.

```bash
# Necesita glslangValidator en el PATH (paquete glslang-tools)
python3 tools/validate_shaders.py

# Crear el .zip listo para shaderpacks/
python3 tools/build_pack.py 1.0.0
```

Resultado actual:

```
[por defecto]     compilados OK: 46   con error: 0
[todo al maximo]  compilados OK: 46   con error: 0
[todo al minimo]  compilados OK: 46   con error: 0
[perfil patata]   compilados OK: 46   con error: 0
```

> La validación comprueba que el código GLSL es correcto y coherente con la API de
> Iris, pero no sustituye a probarlo en el juego. Si ves algo raro, abre un *issue*
> con tu versión de Iris, la captura y el `latest.log`.

---

## 🔧 Personalización

- **Añadir bloques que se mecen**: edita `shaders/block.properties` y añade el
  nombre del bloque (`minecraft:mi_bloque`) al ID `100` (plantas) o `101` (hojas).
  En versiones anteriores a 1.20.5 el bloque de hierba se llama `minecraft:grass`
  en lugar de `minecraft:short_grass`.
- **Cambiar el ID de la lava**: si usas un mod que añade fluidos, añádelos al ID
  `102` para que se dibujen incandescentes.
- **Parámetros internos**: `shaders/lib/settings.glsl` (bias de sombras, IDs de
  bloques) y las fuerzas del viento en `gbuffers_terrain.vsh` / `gbuffers_water.vsh`.

---

## 🩺 Solución de problemas

| Problema | Solución |
|---|---|
| El pack no aparece en la lista | Comprueba que dentro del `.zip` haya una carpeta llamada `shaders` (no una carpeta de más). |
| Sombra con "acné" (rayas) en superficies | Sube `SHADOW_SOFTNESS` o baja `shadowDistance`. |
| Las sombras se ven borrosas o con bordes duros | Ajusta `SHADOW_SOFTNESS` y `shadowMapResolution`. |
| Va lento | Usa el perfil **PATATA** o **RÁPIDO**, o desactiva `BLOOM` y `SHADOWS`. |
| El agua o la hierba no se mueven | Comprueba que `WATER_WAVES` / `WAVING_PLANTS` estén activados. |
| Un bloque nuevo no se mece | Añádelo a `block.properties` (ID 100 o 101). |

---

## 📜 Licencia

MIT — puedes usarlo, modificarlo y redistribuirlo citando el proyecto.
No incluye texturas: usa las de Minecraft.

Hecho con cariño para la comunidad de shaders en español. 🇨🇴
