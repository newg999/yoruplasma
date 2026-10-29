// ============================================================================
//  Música/vídeo que suena (Spotify, YouTube en Brave, mpv...), como la isla
//  de la barra de Yoru (BarraIslas.qml, «Música»):
//    󰝚 · canción · artista · anterior · play/pausa · siguiente
//  Sin reproductor, no ocupa nada.
//    󰝚 y la canción: clic = traer el reproductor · clic central = pausa
// ============================================================================
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: raiz

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function g(codigo) { return String.fromCodePoint(codigo); }

    Mpris.Mpris2Model { id: reproductores }
    readonly property var reproductor: reproductores.currentPlayer
    readonly property bool sonando: reproductor?.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property string cancion: {
        const r = reproductor;
        if (!r)
            return "";
        const titulo = r.track ?? "";
        const artista = r.artist ?? "";
        return artista && titulo ? `${titulo} · ${artista}` : (titulo || artista || (r.identity ?? ""));
    }

    fullRepresentation: RowLayout {
        spacing: 4
        visible: raiz.reproductor !== null
        Layout.minimumWidth: visible ? implicitWidth : 0
        Layout.preferredWidth: visible ? implicitWidth : 0
        Layout.maximumWidth: visible ? implicitWidth : 0

        Ficha {
            icono: raiz.g(0xf075a)
            activa: raiz.sonando
            onClic: boton => boton === Qt.MiddleButton ? raiz.reproductor.PlayPause() : raiz.reproductor.Raise()
        }

        Item {
            implicitWidth: texto.width + 16
            implicitHeight: 22
            Text {
                id: texto
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                text: raiz.cancion
                color: Kirigami.Theme.textColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 240)
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: e => e.button === Qt.MiddleButton ? raiz.reproductor.PlayPause() : raiz.reproductor.Raise()
            }
        }

        Ficha {
            icono: raiz.g(0xf04ae); tamIcono: 11
            apagada: !(raiz.reproductor?.canGoPrevious ?? false)
            onClic: raiz.reproductor.Previous()
        }
        Ficha {
            icono: raiz.sonando ? raiz.g(0xf03e4) : raiz.g(0xf040a); tamIcono: 12
            onClic: raiz.reproductor.PlayPause()
        }
        Ficha {
            icono: raiz.g(0xf04ad); tamIcono: 11
            apagada: !(raiz.reproductor?.canGoNext ?? false)
            onClic: raiz.reproductor.Next()
        }
    }
}
