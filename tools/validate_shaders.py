#!/usr/bin/env python3
"""
Validador de Andes Shaders.

Emula lo mas posible la forma en la que Iris/OptiFine cargan un shader pack,
sin abrir Minecraft:

  1. Descubre las opciones del pack igual que Iris: SOLO en el codigo GLSL
     (.vsh/.fsh y los archivos que estos incluyen via #include).  Los "#define"
     que se pongan en shaders.properties NO definen ninguna opcion, y por eso
     aqui NO se inyecta ninguna macro: si una opcion solo existe en
     shaders.properties, aqui tambien dara error de compilacion (igual que en
     el juego).
  2. Aplica los valores de las opciones como hace Iris: reescribiendo la linea
     del #define / const correspondiente.
  3. Compila cada programa con glslang en varias configuraciones:
     por defecto, todo al maximo, todo al minimo y el perfil PATATA.
  4. Comprobaciones estaticas: uniforms de la API de Iris/OptiFine, atributos
     permitidos, RENDERTARGETS, varyings y que las opciones de los menus,
     sliders y perfiles existan de verdad en el codigo GLSL.

Uso:
    python3 tools/validate_shaders.py [--glslang RUTA] [--profile NOMBRE]
"""

import argparse
import os
import re
import shutil
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

RE_PROGRAM = re.compile(r"^(?:gbuffers_[a-z_]+|shadow[a-z_]*|composite\d*|final|deferred\d*|prepare\d*|begin\d*|setup\d*)$")
RE_UNIFORM = re.compile(r"^\s*uniform\s+[\w\d]+\s+([\w\d]+)\s*(\[[^\]]*\])?\s*;", re.M)
RE_ATTRIB = re.compile(r"^\s*attribute\s+[\w\d]+\s+([\w\d]+)\s*;", re.M)
RE_INCLUDE = re.compile(r'^\s*#include\s+"([^"]+)"')
RE_VARYING = re.compile(r"^\s*varying\s+([\w\d]+)\s+([\w\d]+)\s*;", re.M)
RE_STAGE_MACRO = re.compile(r"\bMC_RENDER_STAGE_[A-Z_]+\b")
RE_FEATURE_MACRO = re.compile(r"\bIRIS_[A-Z_]+\b")

# Nombres "const" que Iris reconoce como opciones (OptionAnnotatedSource)
VALID_CONST_OPTION_NAMES = {
    "shadowMapResolution", "shadowDistance", "voxelDistance", "shadowDistanceRenderMul",
    "entityShadowDistanceMul", "shadowIntervalSize", "generateShadowMipmap",
    "generateShadowColorMipmap", "shadowHardwareFiltering", "shadowtex0Mipmap",
    "shadowtexMipmap", "shadowtex1Mipmap", "shadowtex0Nearest", "shadowtexNearest",
    "shadow0MinMagNearest", "shadowtex1Nearest", "shadow1MinMagNearest",
    "wetnessHalflife", "drynessHalflife", "eyeBrightnessHalflife",
    "centerDepthHalflife", "sunPathRotation", "ambientOcclusionLevel",
    "superSamplingLevel", "noiseTextureResolution",
}

KNOWN_IRIS_MACROS = {
    "MC_VERSION", "MC_GL_VERSION", "MC_GLSL_VERSION", "MC_OS_WINDOWS", "MC_OS_MAC",
    "MC_OS_LINUX", "MC_OS_OTHER", "MC_GL_VENDOR_AMD", "MC_GL_VENDOR_ATI",
    "MC_GL_VENDOR_INTEL", "MC_GL_VENDOR_MESA", "MC_GL_VENDOR_NVIDIA",
    "MC_GL_VENDOR_XORG", "MC_GL_VENDOR_OTHER", "MC_GL_RENDERER_RADEON",
    "MC_GL_RENDERER_GEFORCE", "MC_GL_RENDERER_QUADRO", "MC_GL_RENDERER_INTEL",
    "MC_GL_RENDERER_GALLIUM", "MC_GL_RENDERER_MESA", "MC_GL_RENDERER_OTHER",
    "MC_NORMAL_MAP", "MC_SPECULAR_MAP", "MC_RENDER_QUALITY", "MC_SHADOW_QUALITY",
    "MC_HAND_DEPTH", "MC_OLD_HAND_LIGHT", "MC_OLD_LIGHTING",
    "MC_ANISOTROPIC_FILTERING", "MC_TEXTURE_FORMAT_LAB_PBR",
    "MC_TEXTURE_FORMAT_LAB_PBR_1_3", "MC_USE_SHADOW",
    "IS_IRIS", "IRIS_VERSION", "IRIS_TAG_SUPPORT", "IRIS_HAS_CONNECTED_TEXTURES",
    "IRIS_HAS_TRANSLUCENCY_SORTING", "DIMENSION", "NETHER", "END", "OVERWORLD",
    "GL_LINEAR", "GL_EXP", "GL_EXP2",
}

# ------------------------------------------------------------------ parsing --
RE_IFDEF_REF = re.compile(r"^#(?:ifdef|ifndef)\s+([A-Za-z_][A-Za-z0-9_]*)\s*$")
RE_IF_EXPR = re.compile(r"#(?:if|elif)\s+([^\n]*)")
RE_DEFINE_LINE = re.compile(r"^#define\s+([A-Za-z_][A-Za-z0-9_]*)\s*(.*)$")
RE_CONST_LINE = re.compile(
    r"^const\s+(int|float|bool)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
    r"([\w.+-]+)\s*;\s*(?://\s*(.*))?$")


class Option:
    """Una opcion declarada en el codigo GLSL."""

    def __init__(self, name, kind, default, allowed, comment, path, line_index):
        self.name = name
        self.kind = kind            # "bool" | "value"
        self.default = default      # bool o str
        self.allowed = allowed      # lista de str (vacia si no hay lista)
        self.comment = comment or ""
        self.path = path
        self.line_index = line_index

    def __repr__(self):
        return f"{self.name}={self.default!r} ({self.kind}, {os.path.relpath(self.path, ROOT)}:{self.line_index + 1})"


def find_programs():
    return sorted(
        f for f in os.listdir(SHADERS)
        if (f.endswith(".vsh") or f.endswith(".fsh")) and RE_PROGRAM.match(f.rsplit(".", 1)[0])
    )


def resolve_include(from_path, target):
    if target.startswith("/"):
        return os.path.join(SHADERS, target[1:])
    return os.path.join(os.path.dirname(from_path), target)


def read_lines(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read().split("\n")


def collect_graph(programs):
    """Todos los archivos alcanzables desde los programas via #include."""
    files = {}
    queue = [os.path.join(SHADERS, p) for p in programs]
    while queue:
        path = queue.pop()
        if path in files:
            continue
        if not os.path.exists(path):
            files[path] = None
            continue
        lines = read_lines(path)
        files[path] = lines
        for line in lines:
            match = RE_INCLUDE.match(line)
            if match:
                queue.append(resolve_include(path, match.group(1)))
    return files


def parse_allowed_values(comment):
    if not comment:
        return []
    match = re.search(r"\[([^\]]*)\]", comment)
    if not match:
        return []
    return match.group(1).split()


def annotate(path, lines):
    """Devuelve (opciones, referencias #ifdef/#ifndef, #defines) de un archivo."""
    options = []
    references = set()
    defines = set()

    for index, raw in enumerate(lines):
        line = raw.strip()
        if not any(token in line for token in ("#define", "const", "#ifdef", "#ifndef")):
            continue

        match = RE_IFDEF_REF.match(line)
        if match:
            references.add(match.group(1))
            continue

        if line.startswith("const"):
            match = RE_CONST_LINE.match(line)
            if match:
                type_name, name, value, comment = match.groups()
                defines.add(name)
                if name in VALID_CONST_OPTION_NAMES:
                    if type_name == "bool":
                        options.append(Option(name, "bool", value == "true", [], comment, path, index))
                    elif parse_allowed_values(comment):
                        options.append(Option(name, "value", value, parse_allowed_values(comment), comment, path, index))
            continue

        if "#define" in line:
            body = line
            leading_comment = body.startswith("//")
            if leading_comment:
                body = body.lstrip("/").strip()
            match = RE_DEFINE_LINE.match(body)
            if not match:
                continue
            name, rest = match.group(1), match.group(2).strip()
            defines.add(name)
            if rest == "" or rest.startswith("//"):
                comment = rest[2:].strip() if rest.startswith("//") else ""
                options.append(Option(name, "bool", not leading_comment, [], comment, path, index))
                continue
            if leading_comment:
                continue  # un #define comentado con valor no es una opcion valida
            value_match = re.match(r"^([\w.+-]+)\s*(.*)$", rest)
            if not value_match:
                continue
            value, after = value_match.group(1), value_match.group(2).strip()
            if not after.startswith("//"):
                continue  # sin comentario no hay lista de valores -> no es opcion
            comment = after[2:].strip()
            allowed = parse_allowed_values(comment)
            if not allowed:
                continue
            options.append(Option(name, "value", value, allowed, comment, path, index))

    return options, references, defines


def discover_options(files):
    """Emula el descubrimiento de opciones de Iris (ShaderPackOptions)."""
    references = set()
    all_defines = set()
    found = []
    for path, lines in files.items():
        if lines is None:
            continue
        options, refs, defines = annotate(path, lines)
        references |= refs
        all_defines |= defines
        found.extend(options)

    by_name = {}
    ambiguous = set()
    for option in found:
        if option.kind == "bool" and option.name not in references:
            # Iris solo reconoce una opcion booleana si hay un #ifdef/#ifndef
            continue
        existing = by_name.get(option.name)
        if existing is None:
            by_name[option.name] = option
        elif existing.default != option.default or existing.kind != option.kind:
            ambiguous.add(option.name)
    for name in ambiguous:
        by_name.pop(name, None)
    return by_name, references, all_defines, ambiguous


def apply_edit(lines, option, new_value):
    """Reescribe la linea del #define/const como hace Iris (edit())."""
    index = option.line_index
    line = lines[index]

    if option.kind == "bool":
        is_commented = line.strip().startswith("//")
        if new_value is True:
            if is_commented:
                lines[index] = line.lstrip()[2:].lstrip()
        elif new_value is False:
            if not is_commented:
                lines[index] = "//" + line
        return lines

    if line.lstrip().startswith("const"):
        lines[index] = line.replace(str(option.default), str(new_value), 1)
    else:
        comment = ""
        if "//" in line:
            comment = "//" + line.split("//", 1)[1]
        lines[index] = (f"#define {option.name} {new_value} {comment}").rstrip()
    return lines


def build_source(program_path, edited, cache):
    """Expande los #include de un programa (como el IncludeProcessor de Iris)."""
    if program_path in cache:
        return cache[program_path]
    lines = edited.get(program_path)
    if lines is None:
        return None
    out = []
    for line in lines:
        match = RE_INCLUDE.match(line)
        if match:
            target = resolve_include(program_path, match.group(1))
            included = build_source(target, edited, cache)
            if included is None:
                raise FileNotFoundError(f"#include no encontrado: {match.group(1)} (desde {program_path})")
            out.extend(included)
        else:
            out.append(line)
    cache[program_path] = out
    return out


# ------------------------------------------------------------------ checks --
# Declaraciones globales que no se pueden repetir dentro de un mismo programa.
# (uniform NAME, attribute NAME y varying TIPO NAME -> el nombre es el grupo
# indicado en cada expresion regular.)
RE_DECLARATIONS = (
    ("uniform", RE_UNIFORM, 1),
    ("attribute", RE_ATTRIB, 1),
    ("varying", RE_VARYING, 2),
)


def check_redeclarations(src):
    """Avisa de un uniform/attribute/varying declarado dos veces en el mismo
    programa (por ejemplo, en un .vsh y en una libreria que incluye).

    Los compiladores de NVIDIA abortan con `error C1038: declaration of "X"
    conflicts with previous declaration`; otros lo toleran, asi que hay que
    detectarlo aqui, antes de abrir Minecraft."""
    problems = []
    seen = {}
    for kind, regex, group in RE_DECLARATIONS:
        for match in regex.finditer(src):
            declared = match.group(group)
            line = src.count("\n", 0, match.start()) + 1
            if declared in seen:
                first_kind, first_line = seen[declared]
                problems.append(
                    f"'{declared}' se declara dos veces en el programa "
                    f"({first_kind} en la linea {first_line} y {kind} en la linea {line}); "
                    f"en NVIDIA eso es el error C1038")
            else:
                seen[declared] = (kind, line)
    return problems


def warn_checks(name, src):
    problems = []
    problems += check_redeclarations(src)
    for macro in RE_ATTRIB.findall(src):
        allowed = ATTRIBUTES_OK.get(macro)
        if allowed is not None and name not in allowed:
            problems.append(f"atributo '{macro}' no permitido en {name} (permitido en {sorted(allowed)})")
    for match in RE_UNIFORM.finditer(src):
        macro = match.group(1)
        if macro not in UNIFORMS_OK:
            problems.append(f"uniform desconocido: '{macro}' (revisa la API de Iris/OptiFine)")
    return problems


def check_option_macros(files, options, references, all_defines):
    """Macros usados en #if/#ifdef que no existen en ningun sitio del pack."""
    defined = set(options) | all_defines
    problems = []
    for path, lines in files.items():
        if lines is None:
            continue
        for line in lines:
            for expr in RE_IF_EXPR.findall(line):
                for macro in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", expr):
                    if macro in defined or macro in KNOWN_IRIS_MACROS:
                        continue
                    if macro in {"defined", "if", "elif", "else", "true", "false",
                                 "GL_LINEAR", "GL_EXP", "GL_EXP2"}:
                        continue
                    if RE_STAGE_MACRO.fullmatch(macro) or RE_FEATURE_MACRO.fullmatch(macro):
                        continue
                    problems.append(
                        f"{os.path.relpath(path, SHADERS)}: el macro '{macro}' se usa en un #if "
                        f"pero no esta definido en ninguna parte del GLSL")
    for macro in sorted(references - defined):
        problems.append(f"'{macro}' se usa en un #ifdef/#ifndef pero no hay ningun "
                        f"\"#define {macro}\" en el pack")
    return problems


def check_properties_defines(props_path):
    """Los #define de shaders.properties NO llegan al GLSL: aviso explicito."""
    problems = []
    if not os.path.exists(props_path):
        return problems
    with open(props_path, encoding="utf-8") as fh:
        for number, line in enumerate(fh, start=1):
            if re.match(r"^\s*#define\s", line):
                name = line.split()[1] if len(line.split()) > 1 else "?"
                problems.append(
                    f"shaders.properties:{number}: '#define {name}' no define nada en el GLSL "
                    f"(Iris/OptiFine solo leen opciones de los archivos de shader; muevelo a lib/settings.glsl)")
    return problems


def check_menu_names(props_path, options):
    consts = set()
    settings = os.path.join(SHADERS, "lib", "settings.glsl")
    if os.path.exists(settings):
        with open(settings, encoding="utf-8") as fh:
            consts = set(re.findall(r"^\s*const\s+\w+\s+(\w+)\s*=", fh.read(), re.M))
    known = set(options) | consts
    specials = {"<profile>", "<empty>", "*"}
    problems = []
    if not os.path.exists(props_path):
        return problems
    with open(props_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key, value = key.strip(), value.strip()
            if key.startswith("profile."):
                for token in value.split():
                    name = token.lstrip("!").split(":")[0].split("=")[0]
                    if name and name not in known:
                        problems.append(f"{key}: la opcion '{name}' no existe en el codigo GLSL")
                continue
            if key == "sliders" or key == "screen" or (key.startswith("screen.") and ".columns" not in key):
                for token in value.split():
                    if token in specials or (token.startswith("[") and token.endswith("]")):
                        continue
                    if token not in known:
                        problems.append(f"{key}: la opcion '{token}' no existe en el codigo GLSL")
    return problems


def load_profiles(props_path):
    profiles = {}
    if not os.path.exists(props_path):
        return profiles
    with open(props_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line.startswith("profile.") and "=" in line:
                key, _, value = line.partition("=")
                profiles[key[len("profile."):].strip()] = value.split()
    return profiles


def user_visible_options(options, props_path):
    """Opciones que el jugador puede tocar (menus, sliders o perfiles)."""
    visible = set()
    for name in list(load_profiles(props_path).values()):
        for token in name:
            visible.add(token.lstrip("!").split(":")[0].split("=")[0])
    if os.path.exists(props_path):
        with open(props_path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                key = key.strip()
                if key == "sliders" or key == "screen" or (key.startswith("screen.") and ".columns" not in key):
                    for token in value.split():
                        if token.startswith("["):
                            continue
                        visible.add(token)
    return {name for name in visible if name in options}


def configs_from_options(options, profiles, props_path, profile_name):
    """Configuraciones a probar: por defecto, maximos, minimos y un perfil."""
    configs = [("por defecto", {})]
    visible = user_visible_options(options, props_path)

    def extreme(kind):
        values = {}
        for name in sorted(visible):
            option = options[name]
            if option.kind == "bool":
                values[name] = kind == "max"
                continue
            if not option.allowed:
                continue
            try:
                ordered = sorted(option.allowed, key=float)
            except ValueError:
                ordered = sorted(option.allowed)
            values[name] = ordered[-1] if kind == "max" else ordered[0]
        return values

    max_values = extreme("max")
    min_values = extreme("min")
    configs.append((f"todo al maximo ({len(max_values)} opciones)", max_values))
    configs.append((f"todo al minimo ({len(min_values)} opciones)", min_values))

    if profile_name in profiles:
        values = {}
        for token in profiles[profile_name]:
            if token.startswith("!"):
                values[token[1:]] = False
            elif ":" in token or "=" in token:
                name, value = re.split(r"[:=]", token, 1)
                values[name] = value
            elif token in options:
                values[token] = True
        configs.append((f"perfil {profile_name} ({len(values)} opciones)", values))
    return configs


# -------------------------------------------------------------------- main --
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--glslang", default="glslangValidator")
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--profile", default="PATATA", help="perfil extra a probar")
    args = parser.parse_args()

    props = os.path.join(SHADERS, "shaders.properties")
    programs = find_programs()
    if not programs:
        print("No se han encontrado programas en", SHADERS)
        return 1

    files = collect_graph(programs)
    options, references, all_defines, ambiguous = discover_options(files)
    profiles = load_profiles(props)

    print(f"Programas encontrados: {len(programs)}")
    print(f"Opciones descubiertas en el GLSL: {len(options)}")
    print(f"Perfiles en shaders.properties: {len(profiles)}")

    static_problems = []
    for path, lines in files.items():
        if lines is None:
            static_problems.append(f"#include no encontrado: {os.path.relpath(path, SHADERS)}")
    static_problems += check_properties_defines(props)
    static_problems += check_option_macros(files, options, references, all_defines)
    static_problems += check_menu_names(props, options)
    for name in sorted(ambiguous):
        static_problems.append(f"opcion ambigua (mismo nombre y distinto valor por defecto): '{name}'")

    # Comprobaciones sobre el codigo ya expandido (sin cambios de opciones)
    for program in programs:
        path = os.path.join(SHADERS, program)
        try:
            src = "\n".join(build_source(path, dict(files), {}))
        except FileNotFoundError as exc:
            static_problems.append(str(exc))
            continue
        static_problems += [f"{program}: {p}" for p in warn_checks(program, src)]

        base = program.rsplit(".", 1)[0]
        if program.endswith(".fsh") and base != "final":
            writes = "gl_FragData[" in src or "gl_FragColor" in src
            if writes and "RENDERTARGETS" not in src and "DRAWBUFFERS" not in src:
                static_problems.append(f"{program}: escribe color y no declara /* RENDERTARGETS: N */")

        if program.endswith(".fsh"):
            vsh = program[:-4] + ".vsh"
            if vsh in programs:
                vsh_source = "\n".join(build_source(os.path.join(SHADERS, vsh), dict(files), {}))
                fsh_varyings = {n: k for k, n in RE_VARYING.findall(src)}
                vsh_varyings = {n: k for k, n in RE_VARYING.findall(vsh_source)}
                for name in sorted(set(fsh_varyings) - set(vsh_varyings)):
                    static_problems.append(f"{program}: el varying '{name}' no se declara en {vsh}")
                for name in sorted(set(fsh_varyings) & set(vsh_varyings)):
                    if fsh_varyings[name] != vsh_varyings[name]:
                        static_problems.append(
                            f"{program}: el varying '{name}' es {fsh_varyings[name]} en el .fsh y "
                            f"{vsh_varyings[name]} en el .vsh")

    # Compilacion con glslang, aplicando las opciones igual que Iris
    glslang = shutil.which(args.glslang) or (args.glslang if os.path.exists(args.glslang) else None)
    glslang_errors = 0
    if glslang is None:
        print()
        print(f"AVISO: no se ha encontrado '{args.glslang}'.  Sin glslang solo se hacen")
        print("       las comprobaciones estaticas.  Instala glslang-tools o usa --glslang RUTA.")
    else:
        tmp = tempfile.mkdtemp(prefix="andes-shaders-")
        for config_name, values in configs_from_options(options, profiles, props, args.profile):
            edited = {path: list(lines) for path, lines in files.items() if lines is not None}
            for name, value in values.items():
                option = options.get(name)
                if option is not None:
                    apply_edit(edited[option.path], option, value)

            n_ok, n_fail = 0, 0
            for program in programs:
                stage = "vert" if program.endswith(".vsh") else "frag"
                path = os.path.join(SHADERS, program)
                try:
                    src = "\n".join(build_source(path, edited, {}))
                except FileNotFoundError as exc:
                    n_fail += 1
                    glslang_errors += 1
                    print(f"--- ERROR [{config_name}] {program} ---")
                    print("   ", exc)
                    continue
                tmp_file = os.path.join(tmp, program)
                with open(tmp_file, "w", encoding="utf-8") as fh:
                    fh.write(src)
                proc = subprocess.run([glslang, "-S", stage, tmp_file],
                                      capture_output=True, text=True)
                if proc.returncode != 0:
                    n_fail += 1
                    glslang_errors += 1
                    if not args.quiet:
                        print(f"--- ERROR [{config_name}] {program} ---")
                        for line in (proc.stdout + proc.stderr).strip().splitlines()[:25]:
                            print("   ", line)
                else:
                    n_ok += 1
            print(f"[{config_name}] compilados OK: {n_ok}   con error: {n_fail}")

    print()
    if static_problems:
        print("Avisos de revision manual:")
        for problem in sorted(set(static_problems)):
            print("  -", problem)
    else:
        print("Sin avisos estaticos.")

    print()
    if glslang is None:
        print("RESULTADO: PARCIAL - sin glslang no se ha podido compilar.")
        return 1
    if glslang_errors == 0 and not static_problems:
        print(f"RESULTADO: OK - {len(programs)} programas compilan en todas las configuraciones.")
        return 0
    print(f"RESULTADO: FALLOS - {glslang_errors} errores de compilacion "
          f"y {len(set(static_problems))} avisos.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
