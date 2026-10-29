// ============================================================================
//  Reloj y tiempo, como el centro de la barra de Yoru (BarraIslas.qml):
//  la hora con segundos y, debajo, la fecha; al lado, el tiempo que hace.
//  Clic = calendario, con el tiempo de hoy y de los próximos días.
//
//  El tiempo es el de Open-Meteo, del sitio de ~/.config/yoruplasma/lugar.json
//  («yoruplasma lugar <ciudad>»; si no existe, el de tu IP). Se actualiza
//  cada 15 minutos.
// ============================================================================
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: raiz

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property var dias: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
    readonly property var meses: ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
        "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
    property date ahora: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: raiz.ahora = new Date()
    }

    // ------------------------------------------------------------ Tiempo
    // Como comun/Tiempo.qml de la barra
    property bool listo: false
    property string lugar: ""
    property int temperatura: 0
    property int sensacion: 0
    property int humedad: 0
    property int viento: 0
    property int codigo: 0
    property bool deDia: true
    property string amanecer: ""
    property string atardecer: ""
    property var proximos: []        // [{fecha, max, min, codigo}]

    function g(c) { return String.fromCodePoint(c); }
    function iconoDe(c, dia) {
        if (c === 0) return dia ? g(0xf0599) : g(0xf0594);
        if (c <= 2) return dia ? g(0xf0595) : g(0xf0f31);
        if (c === 3) return g(0xf0590);
        if (c <= 48) return g(0xf0591);
        if (c <= 57) return g(0xf0597);
        if (c <= 67) return g(0xf0596);
        if (c <= 77) return g(0xf0598);
        if (c <= 82) return g(0xf0596);
        if (c <= 86) return g(0xf0598);
        return g(0xf0593);
    }
    function descripcionDe(c) {
        if (c === 0) return "Despejado";
        if (c === 1) return "Casi despejado";
        if (c === 2) return "Parcialmente nublado";
        if (c === 3) return "Nublado";
        if (c <= 48) return "Niebla";
        if (c <= 57) return "Llovizna";
        if (c <= 67) return "Lluvia";
        if (c <= 77) return "Nieve";
        if (c <= 82) return "Chubascos";
        if (c <= 86) return "Chubascos de nieve";
        return "Tormenta";
    }

    function pedir(url, alLlegar) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    alLlegar(JSON.parse(xhr.responseText));
                } catch (e) {
                    console.warn("Tiempo:", e);
                }
            } else {
                reintentar.start();
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    property real latitud: NaN
    property real longitud: NaN
    function actualizar() {
        if (isNaN(latitud))
            return;
        pedir("https://api.open-meteo.com/v1/forecast"
            + `?latitude=${latitud}&longitude=${longitud}&timezone=auto&forecast_days=5`
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset", r => {
            const a = r.current;
            temperatura = Math.round(a.temperature_2m);
            sensacion = Math.round(a.apparent_temperature);
            humedad = a.relative_humidity_2m;
            viento = Math.round(a.wind_speed_10m);
            codigo = a.weather_code;
            deDia = a.is_day === 1;
            amanecer = r.daily.sunrise[0].slice(11, 16);
            atardecer = r.daily.sunset[0].slice(11, 16);
            proximos = r.daily.time.slice(1).map((f, i) => ({
                fecha: f,
                max: Math.round(r.daily.temperature_2m_max[i + 1]),
                min: Math.round(r.daily.temperature_2m_min[i + 1]),
                codigo: r.daily.weather_code[i + 1]
            }));
            listo = true;
        });
    }

    // El lugar: el de lugar.json o, si no hay, por la IP
    P5Support.DataSource {
        id: leerLugar
        engine: "executable"
        connectedSources: ["cat \"${XDG_CONFIG_HOME:-$HOME/.config}/yoruplasma/lugar.json\""]
        onNewData: (fuente, datos) => {
            disconnectSource(fuente);
            try {
                const l = JSON.parse(datos.stdout);
                raiz.lugar = l.nombre ?? "";
                raiz.latitud = l.latitud;
                raiz.longitud = l.longitud;
                raiz.actualizar();
            } catch (e) {
                raiz.porIp();
            }
        }
    }
    function porIp() {
        pedir("http://ip-api.com/json/?fields=city,lat,lon", r => {
            raiz.lugar = r.city;
            raiz.latitud = r.lat;
            raiz.longitud = r.lon;
            raiz.actualizar();
        });
    }
    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: raiz.actualizar()
    }
    // Sin conexión (al arrancar antes que el wifi): se prueba en 1 min
    Timer {
        id: reintentar
        interval: 60 * 1000
        onTriggered: isNaN(raiz.latitud) ? raiz.porIp() : raiz.actualizar()
    }

    // ------------------------------------------------------------ Barra
    compactRepresentation: MouseArea {
        id: barra
        Layout.minimumWidth: fila.implicitWidth
        Layout.preferredWidth: fila.implicitWidth
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: raiz.expanded = !raiz.expanded

        RowLayout {
            id: fila
            anchors.fill: parent
            spacing: 14

            Item { implicitWidth: 10 - fila.spacing }   // relleno de la isla (14 en Yoru, 4 los pone la píldora)

            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: -3
                Text {
                    text: Qt.formatDateTime(raiz.ahora, "HH:mm:ss")
                    color: barra.containsMouse || raiz.expanded ? Kirigami.Theme.textColor : Kirigami.Theme.highlightColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    text: `${raiz.dias[raiz.ahora.getDay()]}, ${raiz.ahora.getDate()} de ${raiz.meses[raiz.ahora.getMonth()]}`
                    color: Kirigami.Theme.disabledTextColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 8
                    font.bold: true
                }
            }

            Row {
                visible: raiz.listo
                Layout.alignment: Qt.AlignVCenter
                spacing: 7
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: raiz.iconoDe(raiz.codigo, raiz.deDia)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: Kirigami.Theme.highlightColor
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: raiz.temperatura + "°C"
                    color: Kirigami.Theme.neutralTextColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            Item { implicitWidth: 10 - fila.spacing }
        }
    }

    // ------------------------------------------------------- Calendario
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 25
        spacing: Kirigami.Units.largeSpacing

        PlasmaCalendar.MonthView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            today: raiz.ahora
            showWeekNumbers: false
        }

        Kirigami.Separator { Layout.fillWidth: true; visible: raiz.listo }

        // El tiempo de hoy
        RowLayout {
            visible: raiz.listo
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            Text {
                text: raiz.iconoDe(raiz.codigo, raiz.deDia)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 34
                color: Kirigami.Theme.highlightColor
            }
            ColumnLayout {
                spacing: 0
                PlasmaComponents.Label {
                    text: `${raiz.temperatura}°C · ${raiz.descripcionDe(raiz.codigo)}`
                    font.bold: true
                }
                PlasmaComponents.Label {
                    text: `${raiz.lugar} · sensación ${raiz.sensacion}° · humedad ${raiz.humedad}% · viento ${raiz.viento} km/h`
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    text: `${raiz.g(0xf059c)} ${raiz.amanecer}   ${raiz.g(0xf059b)} ${raiz.atardecer}`
                    font.family: "JetBrainsMono Nerd Font"
                    opacity: 0.7
                }
            }
        }

        // Los próximos días
        RowLayout {
            visible: raiz.listo
            Layout.fillWidth: true
            Repeater {
                model: raiz.proximos
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: raiz.dias[new Date(modelData.fecha + "T12:00").getDay()].slice(0, 3)
                        opacity: 0.7
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: raiz.iconoDe(modelData.codigo, true)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Kirigami.Theme.textColor
                    }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${modelData.max}° ${modelData.min}°`
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }
        }
    }
}
