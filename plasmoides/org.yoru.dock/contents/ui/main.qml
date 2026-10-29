// ============================================================================
//  Dock, como el de Yoru (config/quickshell/yoru/barra/Dock.qml)
//
//    [fijadas] │ [abiertas que no están fijadas]
//
//    Clic           = ir a su ventana (si ya la tiene delante, la minimiza) ·
//                     si no está abierta, la abre
//    Clic central   = ventana nueva
//    Clic derecho   = menú: ventana nueva, fijar / quitar, cerrar
//
//  Los puntitos de debajo son sus ventanas abiertas; el alargado, la app
//  que tiene el foco. Las fijadas se guardan en la configuración del widget.
//  Es propio (no el gestor de tareas de Plasma) porque aquel da a cada icono
//  una celda tan ancha como el panel y deja los iconos muy separados.
// ============================================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: dock

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Medidas del dock de Yoru
    readonly property int celda: 40          // hueco de cada app
    readonly property int icono: 28

    readonly property color acento: Kirigami.Theme.highlightColor
    function claro(opacidad) { return Qt.rgba(acento.r, acento.g, acento.b, opacidad); }

    TaskManager.TasksModel {
        id: tareas
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        launchInPlace: true
        separateLaunchers: false
        sortMode: TaskManager.TasksModel.SortManual
        filterByVirtualDesktop: false
        filterByScreen: false
        filterByActivity: false
        launcherList: Plasmoid.configuration.launchers
    }

    // Guarda las fijadas cuando cambian (fijar / quitar desde el menú)
    function guardar() {
        Plasmoid.configuration.launchers = tareas.launcherList;
    }

    function pulsar(indice, datos) {
        const i = tareas.makeModelIndex(indice);
        if (datos.IsLauncher)
            tareas.requestActivate(i);
        else if (datos.IsActive && !datos.IsGroupParent)
            tareas.requestToggleMinimized(i);
        else
            tareas.requestActivate(i);
    }

    fullRepresentation: RowLayout {
        spacing: 0
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        Item { implicitWidth: 2 }

        Repeater {
            model: tareas

            RowLayout {
                id: hueco
                required property var model
                required property int index
                spacing: 0
                readonly property bool fija: hueco.model.IsLauncher || hueco.model.HasLauncher
                readonly property int ventanas: hueco.model.IsLauncher ? 0
                    : hueco.model.IsGroupParent ? hueco.model.ChildCount : 1
                // La rayita va antes de la primera app abierta que no está fijada
                readonly property bool primeraSuelta: !fija && hueco.index === tareas.launcherCount
                    && tareas.launcherCount > 0

                Rectangle {
                    visible: hueco.primeraSuelta
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: dock.icono - 4
                    Layout.leftMargin: 3
                    Layout.rightMargin: 3
                    Layout.alignment: Qt.AlignVCenter
                    color: dock.claro(0.15)
                }

                Item {
                    id: elemento
                    Layout.preferredWidth: dock.celda
                    Layout.fillHeight: true

                    // Brillo al pasar el ratón
                    Rectangle {
                        anchors.centerIn: imagen
                        width: dock.icono + 8
                        height: width
                        radius: 9
                        color: dock.acento
                        opacity: raton.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                    }

                    Kirigami.Icon {
                        id: imagen
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -2
                        width: dock.icono
                        height: dock.icono
                        source: hueco.model.decoration
                        // Crece un poco hacia arriba al pasar el ratón
                        transformOrigin: Item.Bottom
                        scale: raton.pressed ? 1.05 : raton.containsMouse ? 1.16 : 1
                        Behavior on scale { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                    }

                    // Ventanas abiertas: hasta 3 puntitos; el de la app con el
                    // foco es alargado, como el escritorio activo de la barra
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: imagen.bottom
                        anchors.topMargin: 3
                        spacing: 3
                        Repeater {
                            model: Math.min(3, hueco.ventanas)
                            Rectangle {
                                required property int index
                                height: 3
                                width: hueco.model.IsActive && index === 0 ? 10 : 3
                                radius: 1.5
                                color: hueco.model.IsActive ? dock.acento : dock.claro(0.55)
                                Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent
                        mainText: hueco.model.AppName || hueco.model.display
                        subText: hueco.model.IsLauncher || hueco.model.AppName === hueco.model.display ? "" : hueco.model.display
                        location: Plasmoid.location
                    }

                    MouseArea {
                        id: raton
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: e => {
                            if (e.button === Qt.RightButton)
                                menu.popup();
                            else if (e.button === Qt.MiddleButton)
                                tareas.requestNewInstance(tareas.makeModelIndex(hueco.index));
                            else
                                dock.pulsar(hueco.index, hueco.model);
                        }
                    }

                    QQC2.Menu {
                        id: menu
                        QQC2.MenuItem {
                            text: "Ventana nueva"
                            icon.name: "window-new"
                            onTriggered: tareas.requestNewInstance(tareas.makeModelIndex(hueco.index))
                        }
                        QQC2.MenuItem {
                            text: hueco.fija ? "Quitar del dock" : "Fijar en el dock"
                            icon.name: hueco.fija ? "window-unpin" : "window-pin"
                            onTriggered: {
                                const url = hueco.model.LauncherUrlWithoutIcon;
                                if (hueco.fija)
                                    tareas.requestRemoveLauncher(url);
                                else
                                    tareas.requestAddLauncher(url);
                                dock.guardar();
                            }
                        }
                        QQC2.MenuSeparator { visible: hueco.ventanas > 0 }
                        QQC2.MenuItem {
                            visible: hueco.ventanas > 0
                            text: hueco.ventanas > 1 ? "Cerrar todas" : "Cerrar"
                            icon.name: "window-close"
                            onTriggered: tareas.requestClose(tareas.makeModelIndex(hueco.index))
                        }
                    }
                }
            }
        }

        Item { implicitWidth: 2 }
    }
}
