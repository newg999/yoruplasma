#!/usr/bin/env python3
# ----------------------------------------------------------------------------
#  estilo.py — El estilo de Plasma «Yoru»: los paneles como las islas de la
#  barra de Yoru (píldoras oscuras y translúcidas, sin borde)
#
#    estilo.py <carpeta>    lo crea en <carpeta> (yoruplasma lo pone en
#                           ~/.local/share/plasma/desktoptheme/yoru)
#
#  Solo cambia el fondo de los paneles. Lo demás (menús, avisos, tooltips)
#  lo coge Plasma de Breeze, su estilo de siempre. Los colores no van aquí:
#  la clase ColorScheme-Background es el fondo del esquema de color «Yoru»
#  (tema.py), así que cambia con «yoruplasma tema».
#
#  Plasma dibuja el fondo de un panel en nueve piezas (esquinas, bordes y
#  centro) y estira los bordes y el centro. Con esquinas de RADIO, queda
#  una píldora, con HUECO transparente encima y debajo: del borde de la
#  pantalla a la isla (margenBarra de Yoru) y de la isla a las ventanas
#  (aVentanas). El aire va dibujado dentro del panel porque Plasma aparta
#  las ventanas solo el grueso del panel (no su margen de flotación), y
#  centra lo de dentro en ese grueso. A los lados, el aire es el margen de
#  flotación (piezas «floating-»). Las piezas «thick-» le dicen a Plasma
#  dónde van los widgets: dentro de la píldora. Los paneles flotan siempre
#  (flotar.sh): si no, Plasma les quita los bordes.
# ----------------------------------------------------------------------------

import gzip
import json
import sys
from pathlib import Path

RADIO = 13        # casi la mitad de los 30 px de la barra: una píldora (con 15
                  # justos, el centro mide 0 y Plasma no dibuja el fondo)
HUECO = 6         # del borde a la isla (margenBarra de Yoru) y de la isla a
                  # las ventanas (aVentanas)
C = 10            # el centro (se estira)
MARGEN_LARGO = 4  # de lo de dentro a los extremos de la píldora (como la isla
                  # de las fichas en Yoru; los widgets de Yoru ponen más)
OPACIDAD = 0.45   # = opacidadIslas de la barra de Yoru

NADA = 'style="fill:#000000;fill-opacity:0"'


def piezas(prefijo, estilo, x0, arriba=0, abajo=0, radio=RADIO):
    """Las nueve piezas de una píldora, cada una con su id. Con «arriba» o
    «abajo», ese aire transparente encima o debajo de la píldora. Plasma mide
    cada pieza por su caja entera: cada una lleva un rectángulo invisible del
    tamaño de la caja y, dentro, lo que se ve"""
    R = radio
    alto_arriba, alto_abajo = arriba + R, abajo + R      # filas de las esquinas
    a = R + C                                            # 3.ª columna
    f = alto_arriba + C                                  # 3.ª fila

    def pieza(nombre, x, y, ancho, alto, dibujo):
        return (f'<g id="{prefijo}{nombre}"><rect {NADA} x="{x0 + x}" y="{y}" width="{ancho}" height="{alto}"/>'
                f'{dibujo}</g>')

    def rect(x, y, ancho, alto):
        return f'<rect {estilo} x="{x0 + x}" y="{y}" width="{ancho}" height="{alto}"/>'

    def arco(x1, y1, x2, y2, giro, cx, cy):
        return (f'<path {estilo} d="M {x0 + x1},{y1} A {R},{R} 0 0 {giro} {x0 + x2},{y2} '
                f'L {x0 + cx},{cy} Z"/>')

    y = arriba                                           # donde empieza la píldora
    return "\n".join([
        pieza("topleft", 0, 0, R, alto_arriba, arco(0, y + R, R, y, 1, R, y + R)),
        pieza("top", R, 0, C, alto_arriba, rect(R, y, C, R)),
        pieza("topright", a, 0, R, alto_arriba, arco(a, y, a + R, y + R, 1, a, y + R)),
        pieza("left", 0, alto_arriba, R, C, rect(0, alto_arriba, R, C)),
        pieza("center", R, alto_arriba, C, C, rect(R, alto_arriba, C, C)),
        pieza("right", a, alto_arriba, R, C, rect(a, alto_arriba, R, C)),
        pieza("bottomleft", 0, f, R, alto_abajo, arco(0, f, R, f + R, 0, R, f)),
        pieza("bottom", R, f, C, alto_abajo, rect(R, f, C, R)),
        pieza("bottomright", a, f, R, alto_abajo, arco(a + R, f, a, f + R, 1, a, f)),
    ])


def margenes(prefijo, arriba, abajo, lado, x0):
    """Las «pistas» de Plasma: cuánto separar lo de dentro de cada borde"""
    pista = lambda nombre, ancho, alto, dx: (f'<rect id="{prefijo}hint-{nombre}-margin" {NADA} '
                                             f'x="{x0 + dx}" y="0" width="{ancho}" height="{alto}"/>')
    return "\n".join([pista("top", 4, arriba, 0), pista("bottom", 4, abajo, 10),
                      pista("left", lado, 4, 20), pista("right", lado, 4, 40)])


def svg(opacidad):
    fondo = f'class="ColorScheme-Background" style="fill:currentColor;fill-opacity:{opacidad}"'
    ancho = 2 * RADIO + C
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{3 * (ancho + 20)}" height="{ancho + 4 * HUECO + 20}">
<style type="text/css" id="current-color-scheme">
    .ColorScheme-Background {{ color:#1a1b1e; }}
</style>
{piezas("", fondo, 0, arriba=HUECO, abajo=HUECO)}
{margenes("", HUECO, HUECO, MARGEN_LARGO, 0)}
{piezas("floating-", NADA, ancho + 20)}
{margenes("floating-", 0.4, 0.4, HUECO, ancho + 20)}
{piezas("thick-", NADA, 2 * (ancho + 20))}
{margenes("thick-", HUECO, HUECO, MARGEN_LARGO, 2 * (ancho + 20))}
</svg>
'''


# El resaltado de las apps del dock (widgets/tasks): lo dibuja el gestor de
# tareas en todo el grueso del panel. Va dibujado dentro de la píldora
# (DENTRO px más adentro), con el acento suave; sus márgenes encajan ahí el
# icono. Las que solo están abiertas, sin nada
DENTRO = 3
RADIO_APP = RADIO - DENTRO


def svg_tareas():
    aire = HUECO + DENTRO
    ancho = 2 * RADIO_APP + C
    acento = lambda opacidad, clase="ColorScheme-Highlight": (
        f'class="{clase}" style="fill:currentColor;fill-opacity:{opacidad}"')
    estados = [("focus", acento(0.18)), ("hover", acento(0.10)),
               ("attention", acento(0.30, "ColorScheme-NegativeText")),
               ("normal", NADA), ("minimized", NADA)]
    partes = []
    for i, (estado, estilo) in enumerate(estados):
        x0 = i * (ancho + 20)
        partes.append(piezas(f"{estado}-", estilo, x0, arriba=aire, abajo=aire, radio=RADIO_APP))
        partes.append(margenes(f"{estado}-", aire + DENTRO, aire + DENTRO, 2 * DENTRO, x0))
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{len(estados) * (ancho + 20)}" height="{ancho + 2 * aire + 20}">
<style type="text/css" id="current-color-scheme">
    .ColorScheme-Highlight {{ color:#ffffff; }}
    .ColorScheme-NegativeText {{ color:#bf616a; }}
</style>
{chr(10).join(partes)}
</svg>
'''


def main():
    if len(sys.argv) != 2:
        sys.exit("uso: estilo.py <carpeta>")
    raiz = Path(sys.argv[1])
    # Plasma usa translucent/ con el escritorio a la vista, opaque/ o solid/
    # con una ventana maximizada o sin efectos: en Yoru las islas no cambian
    for sub in ("", "translucent/", "opaque/", "solid/"):
        destino = raiz / sub / "widgets" / "panel-background.svgz"
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.with_suffix(".svg").unlink(missing_ok=True)   # de versiones anteriores
        destino.write_bytes(gzip.compress(svg(OPACIDAD).encode()))
    (raiz / "widgets" / "tasks.svgz").write_bytes(gzip.compress(svg_tareas().encode()))
    (raiz / "plasmarc").write_text("[AdaptiveTransparency]\nenabled=true\n")
    (raiz / "metadata.json").write_text(json.dumps({
        "KPlugin": {
            "Id": "yoru",
            "Name": "Yoru",
            "Description": "Paneles como las islas de la barra de Yoru",
            "Authors": [{"Name": "Yoru"}],
            "License": "GPL",
            "Version": "1",
        },
        "X-Plasma-API": "5.0",
    }, indent=4) + "\n")


if __name__ == "__main__":
    main()
