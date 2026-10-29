// ============================================================================
//  Estado, como la isla de la derecha de la barra de Yoru (BarraIslas.qml):
//  fichas de red, bluetooth, volumen y batería, y la de los ajustes.
//
//    red        el nombre de la red (y su señal); clic = ajustes de red
//    bluetooth  solo encendido: «On» o cuántos hay conectados
//    volumen    rueda = subir/bajar · clic central = silenciar ·
//               clic = ajustes de sonido · clic derecho = pavucontrol
//    batería    se llena según la carga; clic = ajustes de energía
//    󰍜          las Preferencias del sistema
// ============================================================================
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.volume
import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: raiz

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Los iconos de la barra de Yoru (JetBrainsMono Nerd Font)
    function g(codigo) { return String.fromCodePoint(codigo); }
    readonly property var senales: [g(0xf091f), g(0xf0922), g(0xf0925), g(0xf0928)]

    // Abre un programa (ajustes de red, de sonido...)
    function abrir(orden) { lanzador.connectSource(orden); }
    // Un módulo de las Preferencias de Plasma o, si no está instalado, otro
    // programa (kcmshell6 no falla sin el módulo: abre una ventana de error)
    function abrirAjustes(modulo, siNo) {
        abrir(`kcmshell6 --list | grep -q '^${modulo} ' && exec kcmshell6 ${modulo} || exec ${siNo}`);
    }
    P5Support.DataSource {
        id: lanzador
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    // ----------------------------------------------------------------- Red
    // De nmcli: el tipo de lo conectado, su nombre y, si es wifi, la señal
    property string redTipo: ""      // "wifi", "ethernet" o ""
    property string redNombre: ""
    property int redSenal: 0
    property bool wifiEncendido: true
    readonly property string ordenRed: "nmcli -t -f TYPE,STATE,CONNECTION device; echo ---;"
        + " nmcli -t -f IN-USE,SIGNAL dev wifi list --rescan no; echo ---; nmcli radio wifi"
    P5Support.DataSource {
        id: red
        engine: "executable"
        connectedSources: [raiz.ordenRed]
        interval: 5000
        onNewData: (fuente, datos) => {
            const [dispositivos, redes, radio] = (datos.stdout ?? "").split("---\n");
            const conectado = (dispositivos ?? "").split("\n").map(l => l.split(":"))
                .find(c => (c[0] === "wifi" || c[0] === "ethernet") && c[1] === "connected");
            raiz.redTipo = conectado ? conectado[0] : "";
            raiz.redNombre = conectado ? conectado.slice(2).join(":") : "";
            const enUso = (redes ?? "").split("\n").find(l => l.startsWith("*"));
            raiz.redSenal = enUso ? Number(enUso.split(":")[1]) : 0;
            raiz.wifiEncendido = (radio ?? "").trim() !== "disabled";
        }
    }

    // ----------------------------------------------------------- Bluetooth
    readonly property bool btEncendido: BluezQt.Manager.bluetoothOperational
    property int btConectados: 0
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: raiz.btConectados = BluezQt.Manager.devices.filter(d => d.connected).length
    }

    // ------------------------------------------------------------- Volumen
    SinkModel { id: salidas }   // pone en marcha la conexión con PipeWire
    readonly property var salida: PreferredDevice.sink
    readonly property real volumen: salida ? salida.volume / PulseAudio.NormalVolume : 0
    readonly property bool mudo: salida ? salida.muted : true

    // ------------------------------------------------------------- Batería
    P5Support.DataSource {
        id: energia
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }
    readonly property var bateria: energia.data["Battery"] ?? {}
    readonly property bool hayBateria: bateria["Has Battery"] === true
    readonly property int carga: bateria["Percent"] ?? 0
    readonly property bool cargando: bateria["State"] === "Charging" || bateria["State"] === "FullyCharged"

    fullRepresentation: RowLayout {
        spacing: 4
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        Ficha {
            icono: raiz.redTipo === "ethernet" ? raiz.g(0xf0200)
                : raiz.redTipo === "wifi" ? raiz.senales[Math.min(3, Math.floor(raiz.redSenal / 25))]
                : !raiz.wifiEncendido ? raiz.g(0xf092d) : raiz.g(0xf092e)
            texto: raiz.redTipo === "ethernet" ? "Cable" : raiz.redTipo === "wifi" ? raiz.redNombre : "Sin red"
            visible: raiz.redTipo !== "" || raiz.wifiEncendido
            anchoTexto: 140
            activa: raiz.redTipo !== ""
            onClic: raiz.abrirAjustes("kcm_networkmanagement", "nm-connection-editor")
        }

        Ficha {
            visible: raiz.btEncendido
            icono: raiz.btConectados > 0 ? raiz.g(0xf00b1) : raiz.g(0xf00af)
            texto: raiz.btConectados > 0 ? String(raiz.btConectados) : "On"
            activa: true
            onClic: raiz.abrirAjustes("kcm_bluetooth", "blueman-manager")
        }

        Ficha {
            icono: raiz.mudo ? raiz.g(0xf0581) : raiz.volumen < 0.34 ? raiz.g(0xf057f)
                : raiz.volumen < 0.67 ? raiz.g(0xf0580) : raiz.g(0xf057e)
            texto: Math.round(raiz.volumen * 100) + "%"
            visible: raiz.salida !== null && !raiz.mudo
            onClic: boton => {
                if (boton === Qt.MiddleButton)
                    raiz.salida.muted = !raiz.mudo;
                else if (boton === Qt.RightButton)
                    raiz.abrir("pavucontrol");
                else
                    raiz.abrirAjustes("kcm_pulseaudio", "pavucontrol");
            }
            onRueda: pasos => {
                if (!raiz.salida)
                    return;
                raiz.salida.muted = false;
                const nuevo = Math.max(0, Math.min(1, Math.round(raiz.volumen * 20 + pasos) / 20));
                raiz.salida.volume = Math.round(nuevo * PulseAudio.NormalVolume);
            }
        }

        Ficha {
            visible: raiz.hayBateria
            icono: raiz.cargando ? raiz.g(0xf0084) : raiz.g(0xf0079)
            texto: raiz.carga + "%"
            carga: raiz.carga / 100
            colorIcono: !raiz.cargando && raiz.carga <= 15 ? Kirigami.Theme.negativeTextColor : tinta
            onClic: raiz.abrirAjustes("kcm_powerdevilprofilesconfig", "systemsettings")
        }

        Ficha {
            icono: raiz.g(0xf035c)
            onClic: raiz.abrir("systemsettings")
        }
    }
}
