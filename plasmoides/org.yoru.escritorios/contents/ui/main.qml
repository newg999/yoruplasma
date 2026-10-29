// ============================================================================
//  Escritorios, como en la barra de Yoru (config/quickshell/yoru/barra/
//  Escritorios.qml): el activo es una píldora alargada del color del acento
//  y los demás, circulitos grises. Los que tienen ventanas se ven un poco más
//  claros. Clic = ir a ese escritorio · Rueda = anterior / siguiente
// ============================================================================
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: raiz

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // El acento de Yoru es el color de selección del esquema «Yoru»
    readonly property color acento: Kirigami.Theme.highlightColor
    function claro(opacidad) { return Qt.rgba(acento.r, acento.g, acento.b, opacidad); }

    TaskManager.VirtualDesktopInfo { id: escritorios }

    // Las ventanas, para saber qué escritorios tienen alguna
    TaskManager.TasksModel {
        id: ventanas
        groupMode: TaskManager.TasksModel.GroupDisabled
        onCountChanged: raiz.contar()
        onDataChanged: raiz.contar()
    }
    property var ocupados: ({})     // id de escritorio → true
    function contar() {
        const o = {};
        for (let i = 0; i < ventanas.count; i++) {
            const indice = ventanas.makeModelIndex(i);
            if (!ventanas.data(indice, TaskManager.AbstractTasksModel.IsWindow))
                continue;
            if (ventanas.data(indice, TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops))
                continue;
            for (const d of ventanas.data(indice, TaskManager.AbstractTasksModel.VirtualDesktops) ?? [])
                o[d] = true;
        }
        ocupados = o;
    }
    Component.onCompleted: contar()

    function kwin(metodo, argumentos) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin", path: "/KWin", iface: "org.kde.KWin",
            member: metodo, arguments: argumentos ?? []
        });
    }

    fullRepresentation: RowLayout {
        spacing: 6
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        Item {}   // con «spacing», el aire de la izquierda (como el relleno de la isla en Yoru)

        Repeater {
            model: escritorios.desktopIds

            Item {
                id: escritorio
                required property var modelData
                required property int index
                readonly property bool activo: modelData === escritorios.currentDesktop
                readonly property bool conVentanas: raiz.ocupados[modelData] === true
                readonly property int largo: activo ? 26 : 10

                implicitWidth: punto.width
                Layout.fillHeight: true
                Layout.preferredWidth: punto.width

                Rectangle {
                    id: punto
                    anchors.centerIn: parent
                    width: escritorio.largo
                    height: 10
                    radius: height / 2
                    color: escritorio.activo || raton.containsMouse ? raiz.acento
                        : escritorio.conVentanas ? raiz.claro(0.5)
                        : raiz.claro(0.25)
                    Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
                }

                MouseArea {
                    id: raton
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: raiz.kwin("setCurrentDesktop", [new DBus.int32(escritorio.index + 1)])
                    onWheel: e => raiz.kwin(e.angleDelta.y > 0 ? "previousDesktop" : "nextDesktop")
                }
            }
        }
        Item {}   // y el de la derecha
    }
}
