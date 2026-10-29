# ============================================================================
#  flotar.sh — Las islas de Yoru siempre flotan (Plasma)
#  «yoruplasma» lo enlaza en ~/.config/plasma-workspace/env/, y Plasma lo
#  ejecuta al entrar, antes de poner los paneles.
#
#  Plasma pega los paneles flotantes al borde (sin el aire de alrededor)
#  cuando una ventana los toca, y una ventana maximizada siempre los toca.
#  En Yoru las islas flotan siempre. Esa regla está en el Panel.qml del
#  escritorio de Plasma: se copia el escritorio entero en ~/.local/share
#  (Plasma usa esa copia antes que la del sistema) con una línea cambiada:
#  «ninguna ventana toca el panel».
#
#  Se rehace cada vez que entras, desde el del sistema: tras actualizar
#  Plasma, la copia es de la versión nueva. Si la línea ya no está (Plasma
#  la ha cambiado), no se deja copia y los paneles hacen lo de siempre.
# ============================================================================

# Plasma lo lee con «source»: todo va en un subshell, sin dejar variables
(
    sistema=/usr/share/plasma/shells/org.kde.plasma.desktop
    copia="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/shells/org.kde.plasma.desktop"
    regla='root.touchingWindow = !KWindowSystem.showingDesktop && root.touchingWindowDirect'

    rm -rf "$copia"
    if [ -d "$sistema" ] && grep -q "$regla" "$sistema/contents/views/Panel.qml"; then
        mkdir -p "$(dirname "$copia")"
        cp -r "$sistema" "$copia"
        sed -i "s|$regla|root.touchingWindow = false  // Yoru: las islas siempre flotan (yoruplasma/flotar.sh)|" \
            "$copia/contents/views/Panel.qml"
    fi
)
