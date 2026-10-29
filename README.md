# yoruplasma

Plasma con la cara de Yoru: un escritorio KDE Plasma normal (sus Preferencias
del sistema, sus widgets, sus atajos), pero con la barra en islas, el dock y
los colores de Yoru. No necesita Yoru ni niri: es solo para Plasma.

```
 [ ⠿  ▬ ●  󰝚 canción · artista  󰒮 󰐊 󰒭 ]   [ 12:57:15 󰖕 20°C ]   [ ⋯  TP-Link   On  65%  100% ≡ ]

                                     [ 󰈹  󰆍  󰉋 ]
```

## Qué pone

- **Islas arriba**, píldoras oscuras y translúcidas que siempre flotan (a 6 px
  del borde y de las ventanas, también con una ventana maximizada):
  - izquierda: el menú de apps (Super), los escritorios en puntos y la música
    que suena
  - centro: la hora, la fecha y el tiempo (clic = calendario y el tiempo de
    los próximos días)
  - derecha: la bandeja (los iconos de las apps) y las fichas de red,
    bluetooth, volumen y batería
- **Dock abajo**, siempre a la vista: iconos juntos, puntitos por ventana
- **Colores** en temas (yoru, nord, catppuccin, gruvbox, rose-pine...)
- **Ventanas** sin bordes, con minimizar, maximizar y cerrar
- El escritorio, el de Plasma de siempre: tus archivos y los widgets que pongas

## Instalar

En una sesión de Plasma 6 (Fedora):

```sh
git clone https://github.com/newg999/yoruplasma.git ~/yoruplasma
~/yoruplasma/yoruplasma instalar
```

Instala lo que falte (plasma-nm, bluedevil, iconos Papirus, la fuente
JetBrainsMono Nerd Font y el cursor Bibata), pone la fuente, el cursor y los
iconos, y aplica todo. Borra los paneles que hubiera.

## Usarlo

| Comando | Qué hace |
|---|---|
| `yoruplasma` | Vuelve a poner los paneles, el estilo, los colores y las ventanas (las apps fijadas del dock se quedan) |
| `yoruplasma tema [nombre]` | Cambia los colores; sin nombre, la lista |
| `yoruplasma lugar <ciudad>` | Dónde mirar el tiempo (si no, por tu IP) |

El fondo de pantalla, la fuente y lo demás se cambian en las Preferencias del
sistema, como siempre.

## Cómo está hecho

| Archivo | Qué es |
|---|---|
| `yoruplasma` | El comando |
| `estilo.py` | El estilo de Plasma «Yoru»: el fondo de los paneles (las píldoras) y el resaltado del dock |
| `tema.py`, `temas/` | El esquema de color, desde una paleta de nueve colores |
| `paneles.js` | Los paneles y sus widgets (script de Plasma) |
| `flotar.sh` | Para que los paneles no se peguen al borde con una ventana maximizada (se ejecuta al entrar en Plasma) |
| `plasmoides/` | Los widgets: escritorios, música, reloj, estado y dock |

Sus ajustes van en `~/.config/yoruplasma/` (el tema y el lugar del tiempo).
