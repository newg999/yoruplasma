// ============================================================================
//  Ficha — botón redondo dentro de la isla, como el de la barra de Yoru
//  (config/quickshell/yoru/barra/Ficha.qml): gris oscuro normal, del color
//  del acento con activa: true. Con carga (0 a 1) se llena hasta ahí, como
//  una batería.
// ============================================================================
import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: ficha

    property string icono: ""
    property string texto: ""
    property bool activa: false
    property real carga: -1             // 0..1: llena hasta ahí (-1 = no)
    property bool apagada: false        // gris (sin reproductor...)
    property int tamIcono: 13
    property color colorIcono: tinta
    property int anchoTexto: 0          // > 0 = recorta el texto con "…"
    readonly property alias hover: raton.containsMouse

    signal clic(int boton)
    signal rueda(int pasos)

    readonly property color acento: Kirigami.Theme.highlightColor
    function claro(opacidad) { return Qt.rgba(acento.r, acento.g, acento.b, opacidad); }
    readonly property color tinta: apagada ? claro(0.35) : activa ? Kirigami.Theme.backgroundColor
        : hover ? acento : Kirigami.Theme.textColor

    implicitHeight: 22
    implicitWidth: texto === "" ? implicitHeight : fila.implicitWidth + 2 * (icono === "" ? 10 : 9)
    radius: height / 2
    clip: true
    color: activa ? (hover ? Qt.lighter(acento, 1.1) : acento)
        : hover ? claro(0.14) : claro(0.07)
    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

    // Lo cargado: del color del acento, de la izquierda hasta «carga»
    Rectangle {
        visible: ficha.carga >= 0 && !ficha.activa
        width: parent.width * Math.max(0, Math.min(1, ficha.carga))
        height: parent.height
        radius: ficha.radius
        color: Qt.rgba(ficha.acento.r, ficha.acento.g, ficha.acento.b, 0.35)
    }

    Row {
        id: fila
        anchors.centerIn: parent
        spacing: 6
        Text {
            visible: ficha.icono !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: ficha.icono
            color: ficha.colorIcono
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: ficha.tamIcono
        }
        Text {
            visible: ficha.texto !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: ficha.texto
            color: ficha.tinta
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            elide: Text.ElideRight
            width: ficha.anchoTexto > 0 ? Math.min(implicitWidth, ficha.anchoTexto) : implicitWidth
        }
    }

    MouseArea {
        id: raton
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: e => ficha.clic(e.button)
        onWheel: e => ficha.rueda(e.angleDelta.y > 0 ? 1 : -1)
    }
}
