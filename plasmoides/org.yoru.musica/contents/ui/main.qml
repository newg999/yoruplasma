// ============================================================================
//  Música/vídeo que suena (Spotify, YouTube en Brave, mpv...), como la isla
//  de la barra de Yoru (BarraIslas.qml, «Música»):
//    󰝚 · canción · artista · anterior · play/pausa · siguiente
//  Sin reproductor, no ocupa nada.
//    󰝚 y la canción: clic = su panel · clic central = pausa
//  El panel, como el de Yoru (PaginaSola.qml, «musica»): carátula, canción,
//  artista y reproductor, la barra de progreso (arrastrar, clic o rueda para
//  adelantar o volver) y los botones.
// ============================================================================
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: raiz

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function g(codigo) { return String.fromCodePoint(codigo); }

    Mpris.Mpris2Model { id: reproductores }
    readonly property var reproductor: reproductores.currentPlayer
    readonly property bool sonando: reproductor?.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property string titulo: reproductor?.track || ""
    readonly property bool hayCaratula: String(reproductor?.artUrl ?? "") !== ""
    readonly property string cancion: {
        const r = reproductor;
        if (!r)
            return "";
        const artista = r.artist ?? "";
        return artista && titulo ? `${titulo} · ${artista}` : (titulo || artista || (r.identity ?? ""));
    }

    // Posición y duración, en segundos (MPRIS las da en microsegundos)
    readonly property real duracion: (reproductor?.length ?? 0) / 1e6
    readonly property real posicion: (reproductor?.position ?? 0) / 1e6
    // MPRIS no avisa de la posición: se pregunta cada segundo mientras se ve el panel
    Timer {
        running: raiz.expanded && raiz.sonando
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: raiz.reproductor.updatePosition()
    }
    function tiempo(s) {
        s = Math.max(0, Math.floor(s));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), seg = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${seg}` : `${m}:${seg}`;
    }

    // ------------------------------------------------------------- Isla
    compactRepresentation: RowLayout {
        spacing: 4
        visible: raiz.reproductor !== null
        Layout.minimumWidth: visible ? implicitWidth : 0
        Layout.preferredWidth: visible ? implicitWidth : 0
        Layout.maximumWidth: visible ? implicitWidth : 0

        Ficha {
            icono: raiz.g(0xf075a)
            activa: raiz.sonando || raiz.expanded
            onClic: boton => boton === Qt.MiddleButton ? raiz.reproductor.PlayPause() : raiz.expanded = !raiz.expanded
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
                onClicked: e => e.button === Qt.MiddleButton ? raiz.reproductor.PlayPause() : raiz.expanded = !raiz.expanded
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

    // ------------------------------------------------------------ Panel
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        spacing: 12

        // Carátula, canción, artista y reproductor
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Item {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                Rectangle {
                    anchors.fill: parent
                    visible: !raiz.hayCaratula
                    radius: 10
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                                   Kirigami.Theme.highlightColor.b, 0.06)
                    Text {
                        anchors.centerIn: parent
                        text: raiz.g(0xf075a)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Kirigami.Theme.textColor
                    }
                }
                Kirigami.ShadowedImage {
                    id: caratula
                    anchors.fill: parent
                    visible: raiz.hayCaratula
                    radius: 10
                    source: raiz.reproductor?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(104, 104)
                    asynchronous: true
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: raiz.titulo || "Sin título"
                    color: Kirigami.Theme.highlightColor
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    elide: Text.ElideRight
                    text: raiz.reproductor?.artist ?? ""
                    color: Kirigami.Theme.textColor
                    font.pixelSize: 11
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: "en " + (raiz.reproductor?.identity || "el reproductor")
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 10
                }
            }
        }

        // La barra de progreso, con el tiempo que va y el que dura
        ColumnLayout {
            Layout.fillWidth: true
            visible: raiz.duracion > 0
            spacing: 2
            Deslizador {
                Layout.fillWidth: true
                ondas: raiz.sonando
                valor: raiz.duracion > 0 ? raiz.posicion / raiz.duracion : 0
                onMovido: nuevo => {
                    if (raiz.reproductor?.canSeek)
                        raiz.reproductor.position = Math.round(nuevo * raiz.reproductor.length);
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: raiz.tiempo(raiz.posicion)
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: raiz.tiempo(raiz.duracion)
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 10
                }
            }
        }

        // Anterior · play/pausa · siguiente
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14
            Boton {
                icono: raiz.g(0xf04ae)
                onClic: raiz.reproductor.Previous()
            }
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: playRaton.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                Text {
                    anchors.centerIn: parent
                    text: raiz.sonando ? raiz.g(0xf03e4) : raiz.g(0xf040a)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: Kirigami.Theme.backgroundColor
                }
                MouseArea {
                    id: playRaton
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: raiz.reproductor.PlayPause()
                }
            }
            Boton {
                icono: raiz.g(0xf04ad)
                onClic: raiz.reproductor.Next()
            }
        }
    }

    // Botón redondo con un icono, como BotonIcono de Yoru
    component Boton: Rectangle {
        id: boton
        property string icono
        signal clic()
        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        radius: 8
        color: botonRaton.containsMouse
            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
            : "transparent"
        Text {
            anchors.centerIn: parent
            text: boton.icono
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: botonRaton.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
        }
        MouseArea {
            id: botonRaton
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: boton.clic()
        }
    }
}
