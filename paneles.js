// ============================================================================
//  Paneles de Plasma con la forma de la barra de Yoru
//  Se aplica con «yoruplasma» (en una sesión de Plasma). Borra los paneles
//  que haya y pone:
//    arriba, en islas que se ajustan a lo que llevan:
//      izquierda  el menú de apps (se abre con Super), los escritorios
//                 (puntos) y la música que suena, con los widgets de Yoru
//                 (plasmoides/)
//      centro     la hora, la fecha y el tiempo (clic = calendario)
//      derecha    la bandeja (los iconos de las apps) y las fichas de red,
//                 bluetooth, volumen y batería, como en la barra de Yoru
//    abajo, el dock de Yoru, siempre a la vista, con las apps que ya tuviera
//    fijadas o, la primera vez, las de FIJADAS («yoruplasma» pone ahí el
//    navegador, el terminal y los archivos que encuentre)
//    y el escritorio sin iconos, como en niri (los archivos siguen en
//    ~/Escritorio)
//  API: https://develop.kde.org/docs/plasma/scripting/
// ============================================================================

if (typeof FIJADAS === "undefined")
    var FIJADAS = ["applications:org.kde.dolphin.desktop", "applications:org.kde.konsole.desktop"];

// Las apps que ya tenías fijadas en el dock se quedan
for (const p of panels()) {
    for (const w of p.widgets()) {
        if (w.type !== "org.yoru.dock")
            continue;
        w.currentConfigGroup = ["General"];
        const antes = String(w.readConfig("launchers", "")).split(",").filter(l => l);
        if (antes.length)
            FIJADAS = antes;
    }
}

for (const p of panels())
    p.remove();

// Una isla de arriba, flotante y del tamaño de lo que lleva. El grueso es la
// isla con su aire encima y debajo, que dibuja el estilo Yoru
// (estilo.py)
function isla(alineacion, widgets) {
    const p = new Panel;
    p.location = "top";
    p.height = 42;                                     // 6 + 30 (altoBarra de Yoru) + 6
    p.floating = true;
    p.lengthMode = "fit";
    p.alignment = alineacion;
    p.hiding = "none";
    const hechos = widgets.map(w => p.addWidget(w));
    return {panel: p, widgets: hechos};
}

// ------------------------------------------------------------ Izquierda
const [menu] = isla("left", ["org.kde.plasma.kickoff", "org.yoru.escritorios", "org.yoru.musica"]).widgets;
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "start-here-symbolic");

// --------------------------------------------------------------- Centro
isla("center", ["org.yoru.reloj"]);

// -------------------------------------------------------------- Derecha
// En la bandeja, lo que ya está en las fichas va escondido (en su flecha)
const [bandeja] = isla("right", ["org.kde.plasma.systemtray", "org.yoru.estado"]).widgets;
bandeja.currentConfigGroup = ["General"];
bandeja.writeConfig("hiddenItems", [
    "org.kde.plasma.volume", "org.kde.plasma.battery", "org.kde.plasma.brightness",
    "org.kde.plasma.networkmanagement", "org.kde.plasma.bluetooth",
    "org.kde.plasma.mediacontroller",                   // ya está la isla de música
].join(","));

// ----------------------------------------------------------- Escritorio
// Sin iconos: la vista de carpeta esconde todo lo que coincida con «*»
for (const d of desktops()) {
    d.currentConfigGroup = ["General"];
    d.writeConfig("filterMode", 2);
    d.writeConfig("filterPattern", "*");
}

// ----------------------------------------------------------------- Dock
const dock = new Panel;
dock.location = "bottom";
dock.height = 56;                                      // 6 + 44 + 6
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "none";                                  // siempre a la vista
const apps = dock.addWidget("org.yoru.dock");
apps.currentConfigGroup = ["General"];
apps.writeConfig("launchers", FIJADAS);
