#!/usr/bin/env python3
"""
Validador de Andes Shaders.

Comprueba, sin abrir Minecraft, que el pack es coherente:

  1. Resuelve los #include (como hace Iris/OptiFine) y compila cada programa
     (.vsh con glslang -S vert, .fsh con glslang -S frag).
  2. Repite la compilacion con varias combinaciones de opciones para cubrir
     todas las ramas #ifdef / #if.
  3. Revisa que los uniforms usados existan en la API de Iris/OptiFine.
  4. Revisa que los atributos (mc_Entity, at_midBlock...) se usen solo en los
     programas donde estan permitidos.
  5. Revisa que los .fsh que escriben color lleven la directiva RENDERTARGETS.
  6. Revisa que todos los #ifdef/#ifdef de opciones esten declaradas en
     shaders.properties.

Uso:
    python3 tools/validate_shaders.py [--glslang RUTA]
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHADERS = os.path.join(ROOT, "shaders")

# ---------------------------------------------------------------- uniforms --
UNIFORMS_OK = set("""
gbufferModelView gbufferModelViewInverse gbufferProjection gbufferProjectionInverse
gbufferPreviousModelView gbufferPreviousProjection
shadowModelView shadowModelViewInverse shadowProjection shadowProjectionInverse
modelViewMatrix projectionMatrix textureMatrix
cameraPosition previousCameraPosition eyeAltitude eyePosition relativeEyePosition
eyeBrightness eyeBrightnessSmooth centerDepthSmooth upPosition firstPersonCamera
isEyeInWater blindness darknessFactor nightVision playerMood constantMood
currentPlayerAir currentPlayerHealth hideGUI is_hurt is_burning is_invisible
is_sneaking is_sprinting currentColorSpace
viewWidth viewHeight aspectRatio screenBrightness frameCounter frameTime
frameTimeCounter currentDate currentTime currentYearTime
entityId blockEntityId heldItemId heldItemId2 heldBlockLightValue
heldBlockLightValue2 currentRenderedItemId currentSelectedBlockId
currentSelectedBlockPos vehicleId
sunPosition moonPosition shadowLightPosition sunAngle shadowAngle moonPhase
rainStrength wetness thunderStrength lightningBoltPosition worldTime worldDay
endFlashPosition endFlashIntensity previousEndFlashIntensity
biome biome_category biome_precipitation rainfall temperature ambientLight
bedrockLevel cloudHeight hasCeiling hasSkylight heightLimit logicalHeightLimit
near far alphaTestRef chunkOffset entityColor blendFunc atlasSize renderStage
fogColor skyColor fogDensity fogStart fogEnd fogMode fogShape textureFilteringMode
texture gtexture lightmap
colortex0 colortex1 colortex2 colortex3 colortex4 colortex5 colortex6 colortex7
shadowtex0 shadowtex1 shadowcolor0 shadowcolor1
depthtex0 depthtex1 depthtex2 noisetex
""".split())

# -------------------------------------------------------------- attributes --
ATTRIBUTES_OK = {
    "mc_Entity": {"gbuffers_terrain.vsh", "gbuffers_water.vsh", "shadow.vsh"},
    "at_midBlock": {"gbuffers_terrain.vsh", "gbuffers_water.vsh", "shadow.vsh"},
    "at_tangent": {"gbuffers_terrain.vsh", "gbuffers_water.vsh", "shadow.vsh"},
    "mc_midTexCoord": {"gbuffers_terrain.vsh", "gbuffers_water.vsh", "shadow.vsh"},
    "vaUV2": set(),  # reservado: lo usan los shaders modernos
}

BUILTIN_ATTRIBUTES = {"gl_Vertex", "gl_Normal", "gl_Color", "gl_MultiTexCoord0",
                      "gl_MultiTexCoord1", "gl_MultiTexCoord2", "gl_MultiTexCoord3"}

RE_PROGRAM = re.compile(r"^(?:gbuffers_[a-z_]+|shadow[a-z_]*|composite\d*|final|deferred\d*|prepare\d*|begin\d*|setup\d*)$")
RE_UNIFORM = re.compile(r"^\s*uniform\s+[\w\d]+\s+([\w\d]+)\s*(\[[^\]]*\])?\s*;", re.M)
RE_ATTRIB = re.compile(r"^\s*attribute\s+[\w\d]+\s+([\w\d]+)\s*;", re.M)
RE_INCLUDE = re.compile(r'^\s*#include\s+"([^"]+)"', re.M)
RE_DEFINE = re.compile(r"^#define\s+([A-Za-z_][A-Za-z0-9_]*)\s*(.*)$")
RE_IFMACRO = re.compile(r"#(?:ifdef|ifndef|if|elif)\s+([^\n]*)")
RE_STAGE_MACRO = re.compile(r"\bMC_RENDER_STAGE_[A-Z_]+\b")
RE_FEATURE_MACRO = re.compile(r"\bIRIS_[A-Z_]+\b")

KNOWN_IRIS_MACROS = {
    "MC_VERSION", "MC_GL_VERSION", "MC_GLSL_VERSION", "MC_OS_WINDOWS", "MC_OS_MAC",
    "MC_OS_LINUX", "MC_GL_VENDOR", "MC_GL_RENDERER", "MC_NORMAL_MAP",
    "MC_SPECULAR_MAP", "MC_RENDER_QUALITY", "MC_SHADOW_QUALITY", "MC_HAND_DEPTH",
    "IS_IRIS", "IRIS_VERSION", "IRIS_TAG_SUPPORT", "IRIS_HAS_CONNECTED_TEXTURES",
    "IRIS_HAS_TRANSLUCENCY_SORTING", "MC_ANISOTROPIC_FILTERING", "DIMENSION",
    "NETHER", "END", "OVERWORLD", "MC_TEXTURE_FORMAT", "MC_USE_SHADOW",
}


def load_options(props_path):
    """Lee shaders.properties y devuelve {nombre: (tipo, valores)}."""
    options = {}
    with open(props_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line.startswith("#define"):
                continue
            body = line[len("#define"):].strip()
            # quita el comentario (descripcion y lista de valores)
            comment = ""
            if "//" in body:
                body, comment = body.split("//", 1)
                comment = comment.strip()
            parts = body.split(None, 1)
            if not parts:
                continue
            name = parts[0]
            value = parts[1].strip() if len(parts) > 1 else None
            if value is None:
                options[name] = ("bool", None)
            else:
                values = None
                m = re.match(r"^\[([^\]]*)\]", comment)
                if m:
                    values = m.group(1).split()
                options[name] = ("num", values or [value])
    return options


def build_configs(options):
    """Genera distintas combinaciones de opciones para probar todas las ramas."""
    configs = []

    def defaults():
        cfg = {}
        for name, (kind, values) in options.items():
            cfg[name] = None if kind == "bool" else values[0]
        return cfg

    # 1) valores por defecto (los #define activados y el primer valor de cada lista)
    cfg = defaults()
    for name, (kind, _) in options.items():
        if kind == "bool":
            cfg[name] = True
    configs.append(("por defecto", cfg))

    # 2) todas las opciones booleanas encendidas y todos los numericos al maximo
    cfg = defaults()
    for name, (kind, values) in options.items():
        cfg[name] = True if kind == "bool" else values[-1]
    configs.append(("todo al maximo", cfg))

    # 3) todas las opciones booleanas apagadas y numericos al minimo
    cfg = defaults()
    for name, (kind, values) in options.items():
        cfg[name] = False if kind == "bool" else values[0]
    configs.append(("todo al minimo", cfg))

    # 4) perfil "patata": sin sombras, sin bloom, sin viento
    cfg = defaults()
    for name, (kind, _) in options.items():
        cfg[name] = False if kind == "bool" else cfg[name]
    cfg.update({
        "SHADOWS": False, "BLOOM": False, "WATER_WAVES": False,
        "WAVING_PLANTS": False, "WAVING_LEAVES": False, "FXAA": False,
        "CUSTOM_SKY": False, "CLOUD_SHADING": False, "BLOCKLIGHT_TINT": False,
        "UNDERWATER_TINT": False, "SHADOW_QUALITY": 1 if "SHADOW_QUALITY" in cfg else None,
    })
    configs.append(("perfil patata", cfg))

    return configs


def expand_includes(path, seen=None):
    """Resuelve recursivamente los #include '/lib/...'."""
    with open(path, encoding="utf-8") as fh:
        src = fh.read()

    def repl(match):
        inc = match.group(1)
        if inc.startswith("/"):
            target = os.path.join(SHADERS, inc[1:])
        else:
            target = os.path.join(os.path.dirname(path), inc)
        if not os.path.exists(target):
            raise FileNotFoundError(f"include no encontrado: {inc} (desde {path})")
        return "\n".join(["// >>> inicio de " + inc] + [expand_includes(target)] + ["// <<< fin de " + inc])

    return RE_INCLUDE.sub(repl, src)


def inject_defines(src, defines):
    """Mete los #define de las opciones justo despues de #version."""
    lines = src.split("\n")
    out = []
    version_done = False
    for line in lines:
        out.append(line)
        if not version_done and line.strip().startswith("#version"):
            out.append("// --- opciones del pack (inyectadas por el validador) ---")
            for name, value in defines.items():
                out.append(f"#define {name}" if value is None else f"#define {name} {value}")
            version_done = True
    if not version_done:
        raise ValueError("falta la linea #version")
    return "\n".join(out)


def warn_checks(name, raw_src):
    """Comprobaciones estaticas propias (independientes de glslang)."""
    problems = []

    filename = name if name.endswith((".vsh", ".fsh")) else name
    for macro in RE_ATTRIB.findall(raw_src):
        allowed = ATTRIBUTES_OK.get(macro)
        if allowed is not None and filename not in allowed:
            problems.append(f"atributo '{macro}' no permitido en {name} (permitido en {sorted(allowed)})")

    for match in RE_UNIFORM.finditer(raw_src):
        macro = match.group(1)
        if macro not in UNIFORMS_OK:
            problems.append(f"uniform desconocido: '{macro}' (revisa la API de Iris/OptiFine)")

    return problems


def check_option_macros(files, options):
    """Comprueba que los macros usados en #ifdef existen como opciones."""
    known = set(options)
    problems = []
    for name, src in files.items():
        for expr in RE_IFMACRO.findall(src):
            for macro in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", expr):
                if macro in known or macro in KNOWN_IRIS_MACROS or macro.startswith("ANDES_"):
                    continue
                if macro in {"defined", "if", "elif", "else", "true", "false"}:
                    continue
                if RE_STAGE_MACRO.fullmatch(macro) or RE_FEATURE_MACRO.fullmatch(macro):
                    continue
                if macro.isupper() and macro not in {"GL_LINEAR", "GL_EXP", "GL_EXP2"}:
                    problems.append(f"{name}: el macro '{macro}' se usa en un #if pero no esta definido en shaders.properties")
    return problems


def check_menu_names(props_path, options, shaders_dir):
    """Comprueba que las opciones del menu (screen, sliders, profiles) existen."""
    consts = set()
    settings = os.path.join(shaders_dir, "lib", "settings.glsl")
    if os.path.exists(settings):
        with open(settings, encoding="utf-8") as fh:
            consts = set(re.findall(r"^\s*const\s+\w+\s+(\w+)\s*=", fh.read(), re.M))

    known = set(options) | consts
    specials = {"<profile>", "<empty>", "*"}
    problems = []
    with open(props_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            key, _, value = line.partition("=")
            key, value = key.strip(), value.strip()
            if key.startswith("profile."):
                tokens = value.split()
                for tok in tokens:
                    name = tok.lstrip("!").split(":")[0].split("=")[0]
                    if name and name not in known:
                        problems.append(f"{key}: la opcion '{name}' no existe")
                continue
            if key == "sliders" or key == "screen" or (key.startswith("screen.") and ".columns" not in key):
                for tok in value.split():
                    if tok in specials or (tok.startswith("[") and tok.endswith("]")):
                        continue
                    if tok not in known:
                        problems.append(f"{key}: la opcion '{tok}' no existe")
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--glslang", default="glslangValidator")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    props = os.path.join(SHADERS, "shaders.properties")
    options = load_options(props)
    configs = build_configs(options)

    programs = sorted(
        f for f in os.listdir(SHADERS)
        if (f.endswith(".vsh") or f.endswith(".fsh")) and RE_PROGRAM.match(f.rsplit(".", 1)[0])
    )
    if not programs:
        print("No se han encontrado programas en", SHADERS)
        return 1

    # Carga de fuentes con includes resueltos (para las comprobaciones estaticas)
    sources = {}
    errors = 0
    for prog in programs:
        try:
            sources[prog] = expand_includes(os.path.join(SHADERS, prog))
        except FileNotFoundError as exc:
            print("ERROR:", exc)
            errors += 1

    print(f"Programas encontrados: {len(programs)}")
    print(f"Opciones declaradas en shaders.properties: {len(options)}\n")

    # --- comprobaciones estaticas ---
    static_problems = []
    for prog, src in sources.items():
        static_problems += [f"{prog}: {p}" for p in warn_checks(prog, src)]
    static_problems += check_option_macros(sources, options)
    static_problems += check_menu_names(props, options, SHADERS)

    # --- varyings: los que usa el .fsh deben existir tambien en el .vsh ---
    RE_VARYING = re.compile(r"^\s*varying\s+([\w\d]+)\s+([\w\d]+)\s*;", re.M)
    for prog in programs:
        if not prog.endswith(".fsh"):
            continue
        vsh = prog[:-4] + ".vsh"
        if vsh not in sources:
            continue
        fsh_varyings = {name: kind for kind, name in RE_VARYING.findall(sources[prog])}
        vsh_varyings = {name: kind for kind, name in RE_VARYING.findall(sources[vsh])}
        for missing in sorted(set(fsh_varyings) - set(vsh_varyings)):
            static_problems.append(f"{prog}: el varying '{missing}' no se declara en {vsh}")
        for name in sorted(set(fsh_varyings) & set(vsh_varyings)):
            if fsh_varyings[name] != vsh_varyings[name]:
                static_problems.append(
                    f"{prog}: el varying '{name}' es {fsh_varyings[name]} en el .fsh y "
                    f"{vsh_varyings[name]} en el .vsh")

    # --- RENDERTARGETS ---
    for prog, src in sources.items():
        base = prog.rsplit(".", 1)[0]
        if prog.endswith(".fsh") and base != "final":
            writes = "gl_FragData[" in src or "gl_FragColor" in src or "outColor" in src
            if writes and "RENDERTARGETS" not in src and "DRAWBUFFERS" not in src:
                static_problems.append(f"{prog}: escribe color y no declara /* RENDERTARGETS: N */")

    # --- compilacion con glslang ---
    tmp = tempfile.mkdtemp(prefix="andes-shaders-")
    glslang_errors = 0
    for cfg_name, cfg in configs:
        defines = {}
        for name, value in cfg.items():
            if value is None:
                continue
            if value is False:
                continue  # booleano apagado -> no se define
            defines[name] = None if value is True else str(value)

        n_ok, n_fail = 0, 0
        for prog in programs:
            stage = "vert" if prog.endswith(".vsh") else "frag"
            src = inject_defines(expand_includes(os.path.join(SHADERS, prog)), defines)
            tmp_file = os.path.join(tmp, prog)
            with open(tmp_file, "w", encoding="utf-8") as fh:
                fh.write(src)
            proc = subprocess.run([args.glslang, "-S", stage, tmp_file],
                                  capture_output=True, text=True)
            if proc.returncode != 0:
                n_fail += 1
                glslang_errors += 1
                if not args.quiet:
                    print(f"--- ERROR [{cfg_name}] {prog} ---")
                    for line in (proc.stdout + proc.stderr).strip().splitlines()[:25]:
                        print("   ", line)
            else:
                n_ok += 1
        print(f"[{cfg_name}] compilados OK: {n_ok}   con error: {n_fail}")

    print()
    if static_problems:
        print("Avisos de revision manual:")
        for p in sorted(set(static_problems)):
            print("  -", p)
    else:
        print("Sin avisos estaticos.")

    print()
    if glslang_errors == 0 and errors == 0:
        print(f"RESULTADO: OK - {len(programs)} programas compilan en todas las configuraciones.")
        return 0
    print(f"RESULTADO: FALLOS - {glslang_errors} errores de compilacion.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
