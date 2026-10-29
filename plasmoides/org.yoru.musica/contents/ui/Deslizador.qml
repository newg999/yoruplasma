// ============================================================================
//  Deslizador — el progreso de la canción, como el de la barra de Yoru
//  (comun/Deslizador.qml): la parte hecha es una línea ondulada que avanza
//  mientras «ondas» es true (suena); si no, se aplana.
//  valor va de 0 a 1. Arrastrar, hacer clic o usar la rueda lo cambia y
//  avisa con movido(nuevo).
// ============================================================================
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: deslizador

    property real valor: 0
    property bool ondas: false
    readonly property bool arrastrando: raton.pressed
    signal movido(real nuevo)

    readonly property color acento: Kirigami.Theme.highlightColor

    implicitHeight: 22
    implicitWidth: 200

    // Mientras se arrastra se muestra la posición del ratón (sin esperar al reproductor)
    property real _local: 0
    readonly property real mostrado: arrastrando ? _local : Math.max(0, Math.min(1, valor))

    // La onda: crece y se aplana poco a poco, y se desplaza mientras suena
    property real amplitudOnda: ondas ? 3 : 0
    Behavior on amplitudOnda { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    property real faseOnda: 0
    NumberAnimation on faseOnda {
        running: deslizador.amplitudOnda > 0 && deslizador.visible
        from: 0; to: 2 * Math.PI
        duration: 4000      // una ola cada 4 s: se mueve, pero sin distraer
        loops: Animation.Infinite
    }

    // Lo que falta
    Rectangle {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: deslizador.mostrado * deslizador.width
        height: 4
        radius: 2
        color: Qt.rgba(deslizador.acento.r, deslizador.acento.g, deslizador.acento.b, 0.18)
    }

    // Lo hecho, ondulado
    Canvas {
        id: onda
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 14
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const fin = deslizador.mostrado * width;
            if (fin < 2)
                return;
            const medio = height / 2, ola = 2 * Math.PI / 26;   // una ola cada 26 px
            ctx.strokeStyle = deslizador.acento;
            ctx.lineWidth = 3.5;
            ctx.lineCap = "round";
            ctx.beginPath();
            for (let x = 2; x <= fin; x += 1) {
                const y = medio + deslizador.amplitudOnda * Math.sin(x * ola - deslizador.faseOnda);
                if (x === 2) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.stroke();
        }
        Connections {
            target: deslizador
            function onFaseOndaChanged() { onda.requestPaint(); }
            function onAmplitudOndaChanged() { onda.requestPaint(); }
            function onMostradoChanged() { onda.requestPaint(); }
            function onAcentoChanged() { onda.requestPaint(); }
        }
        onWidthChanged: requestPaint()
    }

    Rectangle {
        width: raton.containsMouse || deslizador.arrastrando ? 18 : 14
        height: width
        radius: width / 2
        color: deslizador.acento
        anchors.verticalCenter: parent.verticalCenter
        x: deslizador.mostrado * (deslizador.width - width)
        Behavior on width { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        Behavior on x {
            enabled: !deslizador.arrastrando
            NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: raton
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function mover(x) {
            deslizador._local = Math.max(0, Math.min(1, (x - 4) / deslizador.width));
            deslizador.movido(deslizador._local);
        }
        onPressed: e => mover(e.x)
        onPositionChanged: e => { if (pressed) mover(e.x); }
        onWheel: e => {
            const paso = e.angleDelta.y > 0 ? 0.05 : -0.05;
            deslizador.movido(Math.max(0, Math.min(1, Math.round((deslizador.valor + paso) * 20) / 20)));
        }
    }
}
