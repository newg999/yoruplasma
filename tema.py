#!/usr/bin/env python3
# ----------------------------------------------------------------------------
#  tema.py — Los colores de Plasma desde una paleta de temas/
#
#    tema.py                  vuelve a aplicar el tema guardado (yoru si no hay)
#    tema.py <nombre>         aplica temas/<nombre>.json (yoru, nord...)
#    tema.py --lista          los temas que hay
#
#  Genera el esquema de color «Yoru» (~/.local/share/color-schemes/
#  YoruPlasma.colors) y lo pone en ~/.config/kdeglobals: Plasma, el estilo
#  de los paneles y los widgets cogen de ahí sus colores. Lo demás de ese
#  archivo (la fuente, lo que cambies en las Preferencias) se queda.
#  El tema elegido se guarda en ~/.config/yoruplasma/tema.
#
#  Una paleta son nueve colores: fondo, fondo2, velo (lo más oscuro), texto,
#  gris, gris2, acento, rojo y amarillo. Los papeles son los de Breeze Dark:
#  velo en las listas, fondo en las ventanas, fondo2 en botones y cabeceras,
#  y el acento en la selección y el foco.
# ----------------------------------------------------------------------------

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
TEMAS = REPO / "temas"
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
ESQUEMAS = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "color-schemes"
ELEGIDO = CONFIG / "yoruplasma" / "tema"
NOMBRE = "YoruPlasma"


def mezcla(c1, c2, t):
    """Del color c1 (t=0) al c2 (t=1)"""
    a = [int(c1[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(c2[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(a, b))


def rgb(color):
    """#rrggbb → «r,g,b», como lo quieren los archivos de KDE"""
    return ",".join(str(int(color[i:i + 2], 16)) for i in (1, 3, 5))


def luminancia(color):
    r, g, b = (int(color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


# Un archivo de KDE (kdeglobals, .colors): [grupos] con clave=valor. Se lee
# y se escribe a mano, conservando el orden y las mayúsculas de las claves
def leer_ini(texto):
    grupos, actual = {}, None
    for linea in texto.splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#"):
            continue
        if linea.startswith("["):
            actual = grupos.setdefault(linea, {})
        elif "=" in linea and actual is not None:
            clave, valor = linea.split("=", 1)
            actual[clave] = valor
    return grupos


def escribir_ini(grupos):
    return "\n".join(g + "\n" + "".join(f"{k}={v}\n" for k, v in claves.items())
                     for g, claves in grupos.items())


def esquema(p):
    a, texto, gris = p["acento"], p["texto"], p["gris"]
    # Sobre el acento, el texto que mejor se lea
    sobre_acento = p["fondo"] if luminancia(a) > luminancia(p["fondo"]) else p["texto"]
    if abs(luminancia(sobre_acento) - luminancia(a)) < 0.3:
        sobre_acento = p["velo"] if luminancia(a) > 0.5 else p["texto"]
    # No hay verde en la paleta: el de Nord, más o menos apagado según el tema
    verde = mezcla("#a3be8c", texto, 0.15)

    def grupo(fondo, alterno, primero=texto, inactivo=gris):
        return {
            "BackgroundAlternate": rgb(alterno),
            "BackgroundNormal": rgb(fondo),
            "DecorationFocus": rgb(a),
            "DecorationHover": rgb(mezcla(a, fondo, 0.4)),
            "ForegroundActive": rgb(a),
            "ForegroundInactive": rgb(inactivo),
            "ForegroundLink": rgb(a),
            "ForegroundNegative": rgb(p["rojo"]),
            "ForegroundNeutral": rgb(p["amarillo"]),
            "ForegroundNormal": rgb(primero),
            "ForegroundPositive": rgb(verde),
            "ForegroundVisited": rgb(mezcla(a, gris, 0.5)),
        }

    seleccion = grupo(a, mezcla(a, p["fondo"], 0.5), primero=sobre_acento,
                      inactivo=mezcla(sobre_acento, a, 0.4))
    seleccion["ForegroundActive"] = rgb(sobre_acento)
    seleccion["ForegroundLink"] = rgb(sobre_acento)
    return {
        "[ColorEffects:Disabled]": {
            "Color": "56,56,56", "ColorAmount": "0", "ColorEffect": "0",
            "ContrastAmount": "0.65", "ContrastEffect": "1",
            "IntensityAmount": "0.1", "IntensityEffect": "2",
        },
        "[ColorEffects:Inactive]": {
            "ChangeSelectionColor": "true", "Color": "112,111,110", "ColorAmount": "0.025",
            "ColorEffect": "2", "ContrastAmount": "0.1", "ContrastEffect": "2", "Enable": "false",
            "IntensityAmount": "0", "IntensityEffect": "0",
        },
        "[Colors:Button]": grupo(p["fondo2"], mezcla(p["fondo2"], a, 0.15)),
        "[Colors:Complementary]": grupo(p["velo"], p["fondo"]),
        "[Colors:Header]": grupo(p["fondo2"], p["fondo"]),
        "[Colors:Header][Inactive]": grupo(p["fondo"], p["fondo2"]),
        "[Colors:Selection]": seleccion,
        "[Colors:Tooltip]": grupo(p["fondo2"], p["fondo"]),
        "[Colors:View]": grupo(p["velo"], mezcla(p["velo"], p["fondo"], 0.5)),
        "[Colors:Window]": grupo(p["fondo"], p["fondo2"]),
        "[General]": {"ColorScheme": NOMBRE, "Name": "Yoru", "shadeSortColumn": "true"},
        "[KDE]": {"contrast": "4"},
        "[WM]": {
            "activeBackground": rgb(p["fondo"]),
            "activeBlend": rgb(texto),
            "activeForeground": rgb(texto),
            "inactiveBackground": rgb(p["velo"]),
            "inactiveBlend": rgb(gris),
            "inactiveForeground": rgb(gris),
        },
    }


def aplicar(p):
    e = esquema(p)
    texto = escribir_ini(e)
    ESQUEMAS.mkdir(parents=True, exist_ok=True)
    (ESQUEMAS / f"{NOMBRE}.colors").write_text(texto)

    destino = CONFIG / "kdeglobals"
    actual = leer_ini(destino.read_text()) if destino.is_file() else {}
    for nombre, claves in e.items():
        if nombre.startswith(("[Colors:", "[ColorEffects:")):
            actual[nombre] = dict(claves)          # los colores, enteros
        else:
            actual.setdefault(nombre, {}).update(claves)
    # Plasma compara esta huella con la del esquema: si no coincide, cree que
    # el esquema ha cambiado y vuelve a aplicar el suyo
    actual["[General]"]["ColorSchemeHash"] = hashlib.sha1(texto.encode()).hexdigest()
    temporal = destino.with_suffix(".tmp")
    temporal.write_text(escribir_ini(actual))
    temporal.replace(destino)
    # Las apps abiertas y Plasma cambian de colores al momento (0 = la paleta)
    subprocess.run(["dbus-send", "--session", "--type=signal", "/KGlobalSettings",
                    "org.kde.KGlobalSettings.notifyChange", "int32:0", "int32:0"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def paleta(nombre):
    datos = json.loads((TEMAS / f"{nombre}.json").read_text())
    return {k: v for k, v in datos.items() if not k.startswith("_")}


def main():
    temas = sorted(a.stem for a in TEMAS.glob("*.json"))
    if sys.argv[1:] == ["--lista"]:
        for t in temas:
            print(t)
        return
    if len(sys.argv) > 1:
        nombre = sys.argv[1]
    elif ELEGIDO.is_file():
        nombre = ELEGIDO.read_text().strip()
    else:
        nombre = "yoru"
    if nombre not in temas:
        sys.exit(f"No conozco el tema «{nombre}»: {' · '.join(temas)}")
    aplicar(paleta(nombre))
    ELEGIDO.parent.mkdir(parents=True, exist_ok=True)
    ELEGIDO.write_text(nombre + "\n")
    print(nombre)


if __name__ == "__main__":
    main()
