#!/usr/bin/env python3
"""Crea el .zip del pack listo para la carpeta shaderpacks de Minecraft.

El zip contiene la carpeta "shaders" en la raiz (como espera Iris/OptiFine)
mas un README.txt de instalacion.

Uso:  python3 tools/build_pack.py [version]
"""
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHADERS = os.path.join(ROOT, "shaders")
RELEASES = os.path.join(ROOT, "releases")

VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"

# Fecha fija dentro del zip: asi dos compilaciones del mismo codigo dan un
# archivo identico (zip reproducible) y el .zip no cambia en cada build.
FIXED_DATE = (2026, 1, 1, 0, 0, 0)


def write_entry(zf, archive_name, data):
    info = zipfile.ZipInfo(archive_name.replace(os.sep, "/"), date_time=FIXED_DATE)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    zf.writestr(info, data)
ZIP_NAME = f"Andes-Shaders-v{VERSION}.zip"

README_TXT = f"""Andes Shaders v{VERSION}
=================================

Shaders para Minecraft Java 1.21.11 con Iris 1.10 o superior
(Fabric, NeoForge o Quilt, junto a Sodium).

Instalacion
-----------
1. Copia este archivo .zip en la carpeta "shaderpacks" de tu instalacion
   de Minecraft (Options > Video Settings > Shader Packs > "Open Shader
   Pack Folder").
2. Dentro del juego: Options > Video Settings > Shader Packs y elige
   "Andes Shaders".
3. Ajusta el pack en "Shader Pack Settings": hay perfiles (Patata, Rapido,
   Equilibrado, Alto, Ultra) y opciones de sombras, agua, viento y color.

Si el pack no aparece en la lista, comprueba que el .zip no tenga una
carpeta de mas: dentro del zip la carpeta debe llamarse "shaders".

Licencia MIT. No incluye texturas: usa las de Minecraft.
"""


def main():
    os.makedirs(RELEASES, exist_ok=True)
    out = os.path.join(RELEASES, ZIP_NAME)
    files = []
    for base, _dirs, names in os.walk(SHADERS):
        for name in sorted(names):
            if name.endswith(".pyc"):
                continue
            full = os.path.join(base, name)
            files.append((full, os.path.relpath(full, ROOT)))

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for full, rel in sorted(files, key=lambda item: item[1]):
            with open(full, "rb") as fh:
                write_entry(zf, rel, fh.read())
        write_entry(zf, "README.txt", README_TXT.encode("utf-8"))

    print(f"Creado {out}")
    print(f"  {len(files)} archivos del pack + README.txt")
    print(f"  tamano: {os.path.getsize(out) / 1024:.1f} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
