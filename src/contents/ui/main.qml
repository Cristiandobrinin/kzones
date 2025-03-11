import QtQuick
import QtQuick.Layouts
import org.kde.kwin
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

import "components" as Components

PlasmaCore.Dialog {

    // api documentation
    // https://api.kde.org/frameworks/plasma-framework/html/classPlasmaQuick_1_1Dialog.html
    // https://api.kde.org/frameworks/plasma-framework/html/classPlasma_1_1Types.html
    // https://develop.kde.org/docs/getting-started/kirigami/style-colors/

    id: mainDialog

    // properties
    property bool shown: false
    property bool moving: false
    property bool moved: false
    property bool resizing: false
    property var clientArea: ({})
    property var cachedClientArea: ({})
    property var displaySize: ({})
    property int currentLayout: 0
    property var screenLayouts: ({})
    property int highlightedZone: -1
    property var activeScreen: null
    property var config: ({})
    property bool showZoneOverlay: config.zoneOverlayShowWhen == 0
    property var errors: []
    property string currentEdgeSnappingZone: ""
    property string currentZone: ""
    property string currentDistance: ""

    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.OnScreenDisplay
    backgroundHints: PlasmaCore.Types.NoBackground
    flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Popup
    visible: false
    outputOnly: true
    opacity: 1
    width: displaySize.width
    height: displaySize.height

    function loadConfig() {

        const defaultLayouts = '[{"name":"Priority Grid","padding":0,"zones":[{"x":0,"y":0,"height":100,"width":25},{"x":25,"y":0,"height":100,"width":50},{"x":75,"y":0,"height":100,"width":25}]},{"name":"Quadrant Grid","zones":[{"x":0,"y":0,"height":50,"width":50},{"x":0,"y":50,"height":50,"width":50},{"x":50,"y":50,"height":50,"width":50},{"x":50,"y":0,"height":50,"width":50}]}]'
       
        let layouts;

        try {
            layouts = JSON.parse(KWin.readConfig("layoutsJson", defaultLayouts));
        } catch (e) {
            errors = errors.concat(`Could not load layouts from configuration, using default layouts.\nError: ${e.message}`);
            layouts = JSON.parse(defaultLayouts);
        }

        // Add a special fullscreen layout that's not shown in the UI but used for the fullscreen preview
        const fullscreenLayout = {
            name: "Fullscreen",
            internal: true, // Mark as internal so it's not shown in the UI
            padding: 5,     // Add padding of 5 as requested
            zones: [
                {
                    x: 0,
                    y: 0,
                    height: 100,
                    width: 100,
                    color: Qt.rgba(0.2, 0.6, 1.0, 0.9) // Match the fullscreen indicator color
                }
            ]
        };
        
        // Store the fullscreen layout index for reference
        config.fullscreenLayoutIndex = layouts.length;
        layouts.push(fullscreenLayout);

        // load values from configuration
        config = {
            // enable zone selector
            enableZoneSelector: KWin.readConfig("enableZoneSelector", true),
            // distance from the top of the screen to trigger the zone selector
            zoneSelectorTriggerDistance: KWin.readConfig("zoneSelectorTriggerDistance", 1),
            // distance from the top of the screen to trigger fullscreen action
            fullscreenTriggerDistance: KWin.readConfig("fullscreenTriggerDistance", 5),
            // enable zone overlay
            enableZoneOverlay: KWin.readConfig("enableZoneOverlay", true),
            // show zone overlay when
            zoneOverlayShowWhen: KWin.readConfig("zoneOverlayShowWhen", 0),
            // highlight target zone
            zoneOverlayHighlightTarget: KWin.readConfig("zoneOverlayHighlightTarget", 0),
            // zone overlay indicator display
            zoneOverlayIndicatorDisplay: KWin.readConfig("zoneOverlayIndicatorDisplay", 0),
            // enable edge snapping
            enableEdgeSnapping: KWin.readConfig("enableEdgeSnapping", false),
            // distance from the edge of the screen to trigger the edge snapping
            edgeSnappingTriggerDistance: KWin.readConfig("edgeSnappingTriggerDistance", 1),
            // enable advanced edge snapping
            enableAdvancedEdgeSnapping: KWin.readConfig("enableAdvancedEdgeSnapping", false),
            // remember window geometries before snapping to a zone, and restore them when the window is removed from their zone
            rememberWindowGeometries: KWin.readConfig("rememberWindowGeometries", true),
            // track active layout per screen
            trackLayoutPerScreen: KWin.readConfig("trackLayoutPerScreen", false),
            // show osd messages
            showOsdMessages: KWin.readConfig("showOsdMessages", true),
            // fade windows while moving
            fadeWindowsWhileMoving: KWin.readConfig("fadeWindowsWhileMoving", false),
            // auto snap all windows
            autoSnapAllNew: KWin.readConfig("autoSnapAllNew", false),
            // layouts
            layouts: layouts,
            // fullscreen layout index
            fullscreenLayoutIndex: config.fullscreenLayoutIndex,
            // filter mode
            filterMode: KWin.readConfig("filterMode", 0),
            // filter list
            filterList: KWin.readConfig("filterList", ""),
            // polling rate in milliseconds
            pollingRate: KWin.readConfig("pollingRate", 100),
            // enable debug logging
            enableDebugLogging: KWin.readConfig("enableDebugLogging", false),
            // enable debug overlay
            enableDebugOverlay: KWin.readConfig("enableDebugOverlay", false)
        };

        // Load edge snapping layouts configuration
        try {
            const defaultEdgeSnappingConfig = {
                zones: {
                    "zone-right-edge": { far: 0, medium: 1, close: 2 },
                    "zone-right-top-edge": { far: 0, medium: 1, close: 1 },
                    "zone-right-bottom-edge": { far: 0, medium: 0, close: 1 },
                    "zone-right-top": { far: 1, medium: 1, close: 0 },
                    "zone-right-bottom": { far: 0, medium: 1, close: 1 },
                    "zone-right-center-outer": { close: 0 },
                    "zone-right-center-inner": { close: 1 },
                    "zone-left-center-outer": { close: 1 },
                    "zone-left-center-inner": { close: 0 },
                    "zone-center": { close: 0 },
                    "zone-center-bottom": { close: 0 },
                    "zone-center-top": { close: 1 },
                    "zone-left-top-outer": { close: 1 },
                    "zone-left-top-inner": { close: 0 },
                    "zone-right-top-outer": { close: 0 },
                    "zone-right-top-inner": { close: 1 },
                    "zone-left-bottom-outer": { close: 0 },
                    "zone-left-bottom-inner": { close: 1 },
                    "zone-right-bottom-outer": { close: 1 },
                    "zone-right-bottom-inner": { close: 0 },
                    "zone-left-edge": { far: 1, medium: 0, close: 1 },
                    "zone-left-top-edge": { far: 1, medium: 1, close: 0 },
                    "zone-left-bottom-edge": { far: 1, medium: 0, close: 1 },
                    "zone-left-top": { far: 1, medium: 0, close: 1 },
                    "zone-left-bottom": { far: 0, medium: 1, close: 0 }
                },
                distances: {
                    "far": [15, 10],
                    "medium": [10, 5],
                    "close": [5, 0]
                }
            };
            
            const edgeSnappingLayoutsJson = KWin.readConfig("edgeSnappingLayoutsJson", JSON.stringify(defaultEdgeSnappingConfig));
            config.edgeSnappingLayouts = JSON.parse(edgeSnappingLayoutsJson);
            
            if (!config.edgeSnappingLayouts.zones || !config.edgeSnappingLayouts.distances) {
                console.log("Invalid edge snapping configuration, using default");
                config.edgeSnappingLayouts = defaultEdgeSnappingConfig;
            }
            
            // Ensure all new center zones are defined
            const newCenterZones = [
                "zone-center", 
                "zone-left-center-outer", "zone-left-center-inner",
                "zone-right-center-outer", "zone-right-center-inner",
                "zone-center-top", "zone-left-top-outer", "zone-left-top-inner", 
                "zone-right-top-outer", "zone-right-top-inner",
                "zone-center-bottom", "zone-left-bottom-outer", "zone-left-bottom-inner", 
                "zone-right-bottom-outer", "zone-right-bottom-inner"
            ];
            
            // Default values for new zones
            const defaultValues = {
                "zone-center": { close: 0 },
                "zone-left-center-outer": { close: 1 },
                "zone-left-center-inner": { close: 0 },
                "zone-right-center-outer": { close: 0 },
                "zone-right-center-inner": { close: 1 },
                "zone-center-top": { close: 1 },
                "zone-left-top-outer": { close: 1 },
                "zone-left-top-inner": { close: 0 },
                "zone-right-top-outer": { close: 0 },
                "zone-right-top-inner": { close: 1 },
                "zone-center-bottom": { close: 0 },
                "zone-left-bottom-outer": { close: 0 },
                "zone-left-bottom-inner": { close: 1 },
                "zone-right-bottom-outer": { close: 1 },
                "zone-right-bottom-inner": { close: 0 }
            };
            
            // Add any missing zones
            for (const zone of newCenterZones) {
                if (!config.edgeSnappingLayouts.zones[zone]) {
                    config.edgeSnappingLayouts.zones[zone] = defaultValues[zone];
                }
            }
            
        } catch (e) {
            errors = errors.concat(`Could not load edge snapping layouts from configuration, using default.\nError: ${e.message}`);
            config.edgeSnappingLayouts = {
                zones: {
                    "zone-right-edge": { far: 0, medium: 1, close: 2 },
                    "zone-right-top-edge": { far: 0, medium: 1, close: 1 },
                    "zone-right-bottom-edge": { far: 0, medium: 0, close: 1 },
                    "zone-right-top": { far: 1, medium: 1, close: 0 },
                    "zone-right-bottom": { far: 0, medium: 1, close: 1 },
                    "zone-right-center-outer": { close: 0 },
                    "zone-right-center-inner": { close: 1 },
                    "zone-left-center-outer": { close: 1 },
                    "zone-left-center-inner": { close: 0 },
                    "zone-center": { close: 0 },
                    "zone-center-bottom": { close: 0 },
                    "zone-center-top": { close: 1 },
                    "zone-left-top-outer": { close: 1 },
                    "zone-left-top-inner": { close: 0 },
                    "zone-right-top-outer": { close: 0 },
                    "zone-right-top-inner": { close: 1 },
                    "zone-left-bottom-outer": { close: 0 },
                    "zone-left-bottom-inner": { close: 1 },
                    "zone-right-bottom-outer": { close: 1 },
                    "zone-right-bottom-inner": { close: 0 },
                    "zone-left-edge": { far: 1, medium: 0, close: 1 },
                    "zone-left-top-edge": { far: 1, medium: 1, close: 0 },
                    "zone-left-bottom-edge": { far: 1, medium: 0, close: 1 },
                    "zone-left-top": { far: 1, medium: 0, close: 1 },
                    "zone-left-bottom": { far: 0, medium: 1, close: 0 }
                },
                distances: {
                    "far": [15, 10],
                    "medium": [10, 5],
                    "close": [5, 0]
                }
            };
        }

        console.log("Config loaded: " + JSON.stringify(config));
    }

    function log(message) {
        if (!config.enableDebugLogging) return;
        console.log("KZones: " + message);
    }

    function show() {
        // show OSD
        mainDialog.shown = true;
        mainDialog.visible = true;
        refreshClientArea();
    }

    function hide() {
        // hide OSD
        mainDialog.shown = false;
        mainDialog.visible = false;
        zoneSelector.expanded = false;
        zoneSelector.near = false;
        zoneSelector.fullscreenRequested = false;
        highlightedZone = -1;
        currentEdgeSnappingZone = "";
        showZoneOverlay = config.zoneOverlayShowWhen == 0;
    }

    function refreshClientArea() {
        activeScreen = Workspace.activeScreen;
        clientArea = Workspace.clientArea(KWin.FullScreenArea, activeScreen, Workspace.currentDesktop);
        displaySize = Workspace.virtualScreenSize;
        currentLayout = getCurrentLayout();
        
        // Check for fullscreen trigger when refreshing client area
        // This helps catch fast cursor movements to the top edge
        if (moving && (Workspace.cursorPos.y - clientArea.y) <= config.fullscreenTriggerDistance) {
            zoneSelector.fullscreenRequested = true;
        }
    }

    function isPointInside(x, y, geometry) {
        return x >= geometry.x && x <= geometry.x + geometry.width && y >= geometry.y && y <= geometry.y + geometry.height;
    }

    function isHovering(item) {
        const itemGlobal = item.mapToGlobal(Qt.point(0, 0));
        return isPointInside(Workspace.cursorPos.x, Workspace.cursorPos.y, {
            x: itemGlobal.x,
            y: itemGlobal.y,
            width: item.width * item.scale,
            height: item.height * item.scale
        });
    }

    function checkFilter(client) {

        if (!client) return false;
        if (!client.normalWindow) return false;
        if (client.popupWindow) return false;
        if (client.skipTaskbar) return false;
        if (!client.resourceClass) return false;
        
        const filter = config.filterList.split(/\r?\n/);
        if (config.filterList.length > 0) {
            if (config.filterMode == 0) {
                // include
                return filter.includes(client.resourceClass.toString());
            }
            if (config.filterMode == 1) {
                // exclude
                return !filter.includes(client.resourceClass.toString());
            }
        }
        return true;
    }

    function matchZone(client) {

        refreshClientArea();

        client.zone = -1;
        // get all zones in the current layout
        const zones = config.layouts[currentLayout].zones;
        // loop through zones and compare with the geometries of the client
        for (let i = 0; i < zones.length; i++) {
            const zone = zones[i];
            const zonePadding = config.layouts[currentLayout].padding || 0;
            const zoneX = ((zone.x / 100) * (clientArea.width - zonePadding)) + zonePadding;
            const zoneY = ((zone.y / 100) * (clientArea.height - zonePadding)) + zonePadding;
            const zoneWidth = ((zone.width / 100) * (clientArea.width - zonePadding)) - zonePadding;
            const zoneHeight = ((zone.height / 100) * (clientArea.height - zonePadding)) - zonePadding;
            if (client.frameGeometry.x == zoneX && client.frameGeometry.y == zoneY && client.frameGeometry.width == zoneWidth && client.frameGeometry.height == zoneHeight) {
                // zone found, set it and exit the loop
                client.zone = i;
                client.zone = currentLayout;
                break;
            }
        }
    }

    function getWindowsInZone(zone, layout) {
        const windows = [];
        for (let i = 0; i < Workspace.stackingOrder.length; i++) {
            const client = Workspace.stackingOrder[i];
            if (client.zone === zone && client.layout === layout && client.desktop === Workspace.currentDesktop && client.activity === Workspace.currentActivity && client.screen === Workspace.activeWindow.screen && checkFilter(client)) {
                windows.push(client);
            }
        }
        return windows;
    }

    function switchWindowInZone(zone, layout, reverse) {
        const clientsInZone = getWindowsInZone(zone, layout);
        if (reverse) clientsInZone.reverse();
        

        // cycle through clients in zone
        if (clientsInZone.length > 0) {
            const index = clientsInZone.indexOf(Workspace.activeWindow);
            if (index === -1) {
                Workspace.activeWindow = clientsInZone[0];
            } else {
                Workspace.activeWindow = clientsInZone[(index + 1) % clientsInZone.length];
            }
        }
    }

    function moveClientToZone(client, zone) {
        // block abnormal windows from being moved (like plasmashell, docks, etc...)
        if (!checkFilter(client)) return;

        if (client && client.resourceClass) {
        log("Moving client " + client.resourceClass.toString() + " to zone " + zone);
        } else {
            log("Moving client to zone " + zone);
        }

        refreshClientArea()
        saveClientProperties(client, zone);

        // Check if fullscreen is requested
        if (zoneSelector.fullscreenRequested) {
            if (client && client.resourceClass) {
            log("Fullscreen requested for client: " + client.resourceClass.toString());
            } else {
                log("Fullscreen requested for client");
            }
            client.setMaximize(true, true);
            zoneSelector.fullscreenRequested = false;
            // Make sure to return early to prevent further zone processing
            return;
        }

        // move client to zone
        if (zone != -1) {
            const zoneItem = zones.repeater.itemAt(zone);
            const itemGlobal = zoneItem.mapToGlobal(Qt.point(0, 0));
            const newGeometry = Qt.rect(Math.round(itemGlobal.x), Math.round(itemGlobal.y), Math.round(zoneItem.width), Math.round(zoneItem.height));
            if (client && client.resourceClass) {
            log("Moving client " + client.resourceClass.toString() + " to zone " + zone + " with geometry " + JSON.stringify(newGeometry));
            } else {
                log("Moving client to zone " + zone + " with geometry " + JSON.stringify(newGeometry));
            }
            client.setMaximize(false, false);
            client.frameGeometry = newGeometry;
        }
    }

    function saveClientProperties(client, zone) {
        if (client && client.resourceClass) {
        log("Saving geometry for client " + client.resourceClass.toString());
        } else {
            log("Saving geometry for client");
        }

        // save current geometry
        if (config.rememberWindowGeometries) {
            const geometry = {
                "x": client.frameGeometry.x,
                "y": client.frameGeometry.y,
                "width": client.frameGeometry.width,
                "height": client.frameGeometry.height
            };
            if (zone != -1) {
                if (client.zone == -1) {
                    client.oldGeometry = geometry;
                }
            }
        }

        // save zone
        client.zone = zone;
        client.layout = currentLayout;
        client.desktop = Workspace.currentDesktop;
        client.activity = Workspace.currentActivity;
    }

    function moveClientToClosestZone(client) {
        if (!checkFilter(client)) return null;

        if (client && client.resourceClass) {
        log("Moving client " + client.resourceClass.toString() + " to closest zone");
        } else {
            log("Moving client to closest zone");
        }

        refreshClientArea();

        const centerPointOfClient = {
            x: client.frameGeometry.x + (client.frameGeometry.width / 2),
            y: client.frameGeometry.y + (client.frameGeometry.height / 2)
        };

        const zones = config.layouts[currentLayout].zones;
        let closestZone = null;
        let closestDistance = Infinity;

        for (let i = 0; i < zones.length; i++) {
            const zone = zones[i];
            const zoneCenter = {
                x: (zone.x + zone.width / 2) / 100 * clientArea.width + clientArea.x,
                y: (zone.y + zone.height / 2) / 100 * clientArea.height + clientArea.y
            };
            const distance = Math.sqrt(Math.pow(centerPointOfClient.x - zoneCenter.x, 2) + Math.pow(centerPointOfClient.y - zoneCenter.y, 2));
            if (distance < closestDistance) {
                closestZone = i;
                closestDistance = distance;
            }
        }

        if (client.zone !== closestZone || client.layout !== currentLayout) moveClientToZone(client, closestZone);
        return closestZone;
    }

    function moveAllClientsToClosestZone() {
        log("Moving all clients to closest zone");
        let count = 0;
        for (let i = 0; i < Workspace.stackingOrder.length; i++) {
            const client = Workspace.stackingOrder[i];
            if (client.move) continue;
            moveClientToClosestZone(client) && count++;
        }
        log("Moved " + count + " clients to closest zone");
        return count;
    }

    function moveClientToNeighbour(client, direction) {
        if (!checkFilter(client)) return null;
        
        if (client && client.resourceClass) {
        log("Moving client " + client.resourceClass.toString() + " to neighbour " + direction);
        } else {
            log("Moving client to neighbour " + direction);
        }

        refreshClientArea();

        const zones = config.layouts[currentLayout].zones;

        if (client.zone === -1 || client.layout !== currentLayout) moveClientToClosestZone(client);

        const currentZone = zones[client.zone];
        let targetZoneIndex = -1;

        let minDistance = Infinity;

        for (let i = 0; i < zones.length; i++) {
            if (i === client.zone) continue;

            const zone = zones[i];
            let isNeighbour = false;
            let distance = Infinity;

            switch (direction) {
                case "left":
                    if (zone.x + zone.width <= currentZone.x && 
                        zone.y < currentZone.y + currentZone.height && 
                        zone.y + zone.height > currentZone.y) {
                        isNeighbour = true;
                        distance = currentZone.x - (zone.x + zone.width);
                    }
                    break;
                case "right":
                    if (zone.x >= currentZone.x + currentZone.width && 
                        zone.y < currentZone.y + currentZone.height && 
                        zone.y + zone.height > currentZone.y) {
                        isNeighbour = true;
                        distance = zone.x - (currentZone.x + currentZone.width);
                    }
                    break;
                case "up":
                    if (zone.y + zone.height <= currentZone.y && 
                        zone.x < currentZone.x + currentZone.width && 
                        zone.x + zone.width > currentZone.x) {
                        isNeighbour = true;
                        distance = currentZone.y - (zone.y + zone.height);
                    }
                    break;
                case "down":
                    if (zone.y >= currentZone.y + currentZone.height && 
                        zone.x < currentZone.x + currentZone.width && 
                        zone.x + zone.width > currentZone.x) {
                        isNeighbour = true;
                        distance = zone.y - (currentZone.y + currentZone.height);
                    }
                    break;
            }

            if (isNeighbour && distance < minDistance) {
                minDistance = distance;
                targetZoneIndex = i;
            }
        }

        if (targetZoneIndex !== -1) {
            moveClientToZone(client, targetZoneIndex);
        }

        return targetZoneIndex;
    }

    function getCurrentLayout() {
        if (config.trackLayoutPerScreen) {
            const screenLayout = screenLayouts[Workspace.activeScreen.name]
            if (!screenLayout) {
                screenLayouts[Workspace.activeScreen.name] = 0
            }
            return screenLayouts[Workspace.activeScreen.name];
        } else {
            return currentLayout;
        }
    }

    function setCurrentLayout(layout) {
        if (config.trackLayoutPerScreen) screenLayouts[Workspace.activeScreen.name] = layout
        currentLayout = layout
    }

    function connectSignals(client) {

        if (!checkFilter(client)) return;

        if (client && client.resourceClass) {
        log("Connecting signals for client " + client.resourceClass.toString());
        } else {
            log("Connecting signals for client");
        }

        client.onInteractiveMoveResizeStarted.connect(onInteractiveMoveResizeStarted);
        client.onInteractiveMoveResizeStepped.connect(onInteractiveMoveResizeStepped);
        client.onInteractiveMoveResizeFinished.connect(onInteractiveMoveResizeFinished);
        client.onFullScreenChanged.connect(onFullScreenChanged);

        function onInteractiveMoveResizeStarted() {
            if (client && client.resourceClass) {
            log("Interactive move/resize started for client " + client.resourceClass.toString());
            } else {
                log("Interactive move/resize started for client");
            }
            
            if (client.resizeable && checkFilter(client)) {
                if (client.move && checkFilter(client)) {
                    cachedClientArea = clientArea;

                    if (config.fadeWindowsWhileMoving) {
                        for (let i = 0; i < Workspace.stackingOrder.length; i++) {
                            const client = Workspace.stackingOrder[i];
                            client.previousOpacity = client.opacity;
                            if (client.move ||!client.normalWindow) continue;
                            client.opacity = 0.5;
                        }
                    }

                    if (config.rememberWindowGeometries && client.zone != -1) {
                        if (client.oldGeometry) {
                            const geometry = client.oldGeometry;
                            const zone = config.layouts[client.layout].zones[client.zone];
                            const zoneCenterX = (zone.x + zone.width / 2) / 100 * cachedClientArea.width + cachedClientArea.x;
                            const zoneX = ((zone.x / 100) * cachedClientArea.width + cachedClientArea.x);
                            const newGeometry = Qt.rect(Math.round(Workspace.cursorPos.x - geometry.width / 2), Math.round(client.frameGeometry.y), Math.round(geometry.width), Math.round(geometry.height));
                            client.frameGeometry = newGeometry;
                        }
                    }

                    moving = true;
                    moved = false;
                    resizing = false;
                    if (client && client.resourceClass) {
                    log("Move start " + client.resourceClass.toString());
                    } else {
                        log("Move start");
                    }
                    mainDialog.show();                      
                }
                if (client.resize) {
                    moving = false;
                    moved = false;
                    resizing = true;
                }
            }
        }

        function onInteractiveMoveResizeStepped() {
            if (client.resizeable) {
                if (moving && checkFilter(client)) {
                    moved = true;
                }
            }
        }

        function onInteractiveMoveResizeFinished() {
            if (client && client.resourceClass) {
            log("Interactive move/resize finished for client " + client.resourceClass.toString());
            } else {
                log("Interactive move/resize finished for client");
            }

            if (config.fadeWindowsWhileMoving) {
                for (let i = 0; i < Workspace.stackingOrder.length; i++) {
                    const client = Workspace.stackingOrder[i];
                    client.opacity = client.previousOpacity || 1;
                }
            }

            if (moving) {
                if (client && client.resourceClass) {
                log("Move end " + client.resourceClass.toString());
                } else {
                    log("Move end for unknown client");
                }
                if (moved) {
                    if (shown) {
                        moveClientToZone(client, highlightedZone);
                    } else {
                        saveClientProperties(client, -1);
                    }
                }
                hide();
            }
            moving = false;
            moved = false;
            resizing = false;
        }

        // fix from https://github.com/gerritdevriese/kzones/pull/25
        function onFullScreenChanged() {
            if (client && client.resourceClass) {
            log("Client fullscreen: " + client.resourceClass.toString() + " (fullscreen " + client.fullScreen + ")");
            } else {
                log("Client fullscreen (fullscreen " + client.fullScreen + ")");
            }
            mainDialog.hide();
        }
        
    }

    Components.ColorHelper {
        id: colorHelper
    }

    Components.Shortcuts {
        onCycleLayouts: {
            setCurrentLayout((currentLayout + 1) % config.layouts.length);
            highlightedZone = -1;
            osdDbus.exec(config.trackLayoutPerScreen ? `${config.layouts[currentLayout].name} (${Workspace.activeScreen.name})` : config.layouts[currentLayout].name);
        }

        onCycleLayoutsReversed: {
            setCurrentLayout((currentLayout - 1 + config.layouts.length) % config.layouts.length);
            highlightedZone = -1;
            osdDbus.exec(config.trackLayoutPerScreen ? `${config.layouts[currentLayout].name} (${Workspace.activeScreen.name})` : config.layouts[currentLayout].name);
        }

        onMoveActiveWindowToNextZone: {
            const client = Workspace.activeWindow;
            if (client.zone == -1) moveClientToClosestZone(client);
            const zonesLength = config.layouts[currentLayout].zones.length;
            moveClientToZone(client, (client.zone + 1) % zonesLength);
        }

        onMoveActiveWindowToPreviousZone: {
            const client = Workspace.activeWindow;
            if (client.zone == -1) moveClientToClosestZone(client);
            const zonesLength = config.layouts[currentLayout].zones.length;
            moveClientToZone(client, (client.zone - 1 + zonesLength) % zonesLength);
        }

        onToggleZoneOverlay: {
            if (!config.enableZoneOverlay) {
                osdDbus.exec("Zone overlay is disabled");
            }
            else if (moving) {
                showZoneOverlay = !showZoneOverlay;
            }
            else {
                osdDbus.exec("The overlay can only be shown while moving a window");
            }
        }

        onSwitchToNextWindowInCurrentZone: {
            switchWindowInZone(Workspace.activeWindow.zone, Workspace.activeWindow.layout);
        }

        onSwitchToPreviousWindowInCurrentZone: {
            switchWindowInZone(Workspace.activeWindow.zone, Workspace.activeWindow.layout, true);
        }
        
        onMoveActiveWindowToZone: {
            moveClientToZone(Workspace.activeWindow, zone);
        }

        onActivateLayout: {
            if (layout <= config.layouts.length - 1) {
                setCurrentLayout(layout);
                highlightedZone = -1;
                osdDbus.exec(config.trackLayoutPerScreen ? `${config.layouts[currentLayout].name} (${Workspace.activeScreen.name})` : config.layouts[currentLayout].name);
            } else {
                osdDbus.exec(`Layout ${layout + 1} does not exist`);
            }
        }

        onMoveActiveWindowUp: {
            moveClientToNeighbour(Workspace.activeWindow, "up");
        }

        onMoveActiveWindowDown: {
            moveClientToNeighbour(Workspace.activeWindow, "down");
        }

        onMoveActiveWindowLeft: {
            moveClientToNeighbour(Workspace.activeWindow, "left");
        }

        onMoveActiveWindowRight: {
            moveClientToNeighbour(Workspace.activeWindow, "right");
        }

        onSnapActiveWindow: {
            moveClientToClosestZone(Workspace.activeWindow);
        }

        onSnapAllWindows: {
            moveAllClientsToClosestZone();
        }
    }

    Component.onCompleted: {
        // refresh client area
        refreshClientArea();
        mainDialog.loadConfig();

        // match all clients to zones and connect signals
        for (let i = 0; i < Workspace.stackingOrder.length; i++) {
            matchZone(Workspace.stackingOrder[i]);
            connectSignals(Workspace.stackingOrder[i]);
        }
    }

    Item {
        id: mainItem

        // main polling timer
        Timer {
            id: timer

            triggeredOnStart: true
            interval: config.pollingRate
            running: shown && moving
            repeat: true

            onTriggered: {
                refreshClientArea();

                // Check if cursor is very close to the top edge for fullscreen action first
                // Use a more aggressive approach for fullscreen detection
                const fullscreenTriggerDistance = config.fullscreenTriggerDistance;
                const isVeryCloseToTop = (Workspace.cursorPos.y - clientArea.y) <= fullscreenTriggerDistance;
                
                // If we're close to the top edge, ONLY show fullscreen indicator and nothing else
                if (isVeryCloseToTop && moving) {
                    if (!zoneSelector.fullscreenRequested) {
                        log("Fullscreen mode activated - cursor at top edge");
                    }
                    
                    // Force fullscreen mode
                    zoneSelector.fullscreenRequested = true;
                    
                    // Show the fullscreen layout preview
                    highlightedZone = 0; // The fullscreen layout has only one zone
                    
                    // Ensure zone selector is not expanded
                    zoneSelector.expanded = false;
                    zoneSelector.near = false;
                    
                    // Hide zone overlay
                    showZoneOverlay = false;
                    
                    // Skip all other detection logic
                    return;
                } else if (zoneSelector.fullscreenRequested) {
                    // Reset fullscreen mode if we're no longer at the top edge
                    log("Fullscreen mode deactivated - cursor moved away from top edge");
                    zoneSelector.fullscreenRequested = false;
                }

                let hoveringZone = -1;

                // zone overlay
                if (config.enableZoneOverlay && showZoneOverlay && !zoneSelector.expanded) {
                    zones.repeater.model.forEach((zone, zoneIndex) => {
                        if (isHovering(zones.repeater.itemAt(zoneIndex).children[config.zoneOverlayHighlightTarget])) {
                            hoveringZone = zoneIndex;
                        }
                    });
                }

                // zone selector - only if not too close to top edge
                if (config.enableZoneSelector && !isVeryCloseToTop) {
                    if (!zoneSelector.animating && zoneSelector.expanded) {
                        zoneSelector.repeater.model.forEach((layout, layoutIndex) => {
                            const layoutItem = zoneSelector.repeater.itemAt(layoutIndex);
                            layout.zones.forEach((zone, zoneIndex) => {
                                const zoneItem = layoutItem.children[zoneIndex];
                                if (isHovering(zoneItem)) {
                                    hoveringZone = zoneIndex;
                                    setCurrentLayout(layoutIndex);
                                }
                            });
                        });
                    }
                    
                    // set zoneSelector expansion state - only if not in fullscreen mode
                    zoneSelector.expanded = !zoneSelector.fullscreenRequested && isHovering(zoneSelector) && (Workspace.cursorPos.y - clientArea.y) >= 0;
                    
                    // set zoneSelector near state
                    const triggerDistance = config.zoneSelectorTriggerDistance * 50 + 25;
                    zoneSelector.near = (Workspace.cursorPos.y - clientArea.y) < zoneSelector.y + zoneSelector.height + triggerDistance;
                }

                // edge snapping - improved to work at screen edges
                // Only check for edge snapping if not in fullscreen mode and not too close to top edge
                if (config.enableEdgeSnapping && !zoneSelector.fullscreenRequested && !isVeryCloseToTop) {
                    const triggerDistance = (config.edgeSnappingTriggerDistance + 1) * 10;
                    
                    // Check if cursor is at or very near the edge
                    const isAtLeftEdge = Workspace.cursorPos.x <= clientArea.x + triggerDistance;
                    const isAtRightEdge = Workspace.cursorPos.x >= clientArea.x + clientArea.width - triggerDistance;
                    const isAtTopEdge = Workspace.cursorPos.y <= clientArea.y + triggerDistance;
                    const isAtBottomEdge = Workspace.cursorPos.y >= clientArea.y + clientArea.height - triggerDistance;
                    
                    // Additional check for cursor at the very edge (within 2 pixels)
                    const veryEdgeDistance = 2;
                    const isAtVeryLeftEdge = Workspace.cursorPos.x <= clientArea.x + veryEdgeDistance;
                    const isAtVeryRightEdge = Workspace.cursorPos.x >= clientArea.x + clientArea.width - veryEdgeDistance;
                    const isAtVeryTopEdge = Workspace.cursorPos.y <= clientArea.y + veryEdgeDistance;
                    const isAtVeryBottomEdge = Workspace.cursorPos.y >= clientArea.y + clientArea.height - veryEdgeDistance;
                    
                    // If at any edge or very edge, check for zones
                    if (isAtLeftEdge || isAtRightEdge || isAtTopEdge || isAtBottomEdge || 
                        isAtVeryLeftEdge || isAtVeryRightEdge || isAtVeryTopEdge || isAtVeryBottomEdge) {
                        
                        zones.repeater.model.forEach((zone, zoneIndex) => {
                            const zoneItem = zones.repeater.itemAt(zoneIndex);
                            const itemGlobal = zoneItem.mapToGlobal(Qt.point(0, 0));
                            const zoneGeometry = {
                                x: itemGlobal.x,
                                y: itemGlobal.y,
                                width: zoneItem.width,
                                height: zoneItem.height
                            };
                            
                            // Enhanced point inside check for edge cases
                            if (isPointInsideEnhanced(Workspace.cursorPos.x, Workspace.cursorPos.y, zoneGeometry, 
                                                    isAtVeryLeftEdge, isAtVeryRightEdge, isAtVeryTopEdge, isAtVeryBottomEdge)) {
                                hoveringZone = zoneIndex;
                            }
                        });
                    }
                }

                // Advanced edge snapping - check if we should change layouts based on cursor position
                if (config.enableAdvancedEdgeSnapping && !zoneSelector.fullscreenRequested && !isVeryCloseToTop) {
                    checkAdvancedEdgeSnapping();
                }
                // For debugging purposes, still detect zones even if advanced edge snapping is disabled
                else if (config.enableDebugLogging && !zoneSelector.fullscreenRequested && !isVeryCloseToTop) {
                    checkAdvancedEdgeSnapping(true);
                }

                // if hovering zone changed from the last frame
                if (hoveringZone != highlightedZone) {
                    log("Highlighting zone " + hoveringZone + " in layout " + currentLayout);
                    highlightedZone = hoveringZone;
                }
            }
        }

        DBusCall {
            id: osdDbus

            service: "org.kde.plasmashell"
            path: "/org/kde/osdService"
            method: "showText"

            function exec(text, icon = "preferences-desktop-virtual") {
                if (!config.showOsdMessages) return;
                this.arguments = [icon, text];
                this.call();
            }
        }

        Item {
            x: clientArea.x || 0
            y: clientArea.y || 0
            width: clientArea.width || 0
            height: clientArea.height || 0
            clip: true

            Components.Debug {
                info: ({
                    activeWindow: {
                        caption: Workspace.activeWindow?.caption,
                        resourceClass: Workspace.activeWindow?.resourceClass?.toString(),
                        frameGeometry: {
                            x: Workspace.activeWindow?.frameGeometry?.x,
                            y: Workspace.activeWindow?.frameGeometry?.y,
                            width: Workspace.activeWindow?.frameGeometry?.width,
                            height: Workspace.activeWindow?.frameGeometry?.height
                        },
                        zone: Workspace.activeWindow?.zone
                    },
                    highlightedZone: highlightedZone,
                    moving: moving,
                    resizing: resizing,
                    oldGeometry: Workspace.activeWindow?.oldGeometry,
                    activeScreen: activeScreen?.name,
                    currentLayout: currentLayout,
                    screenLayouts: screenLayouts,
                    advancedEdgeSnapping: {
                        enabled: config.enableAdvancedEdgeSnapping,
                        currentZone: currentEdgeSnappingZone
                    }
                })
                errors: mainDialog.errors
                config: mainDialog.config
            }

            Components.Zones {
                id: zones
                config: mainDialog.config
                currentLayout: mainDialog.currentLayout
                highlightedZone: mainDialog.highlightedZone
                fullscreenRequested: zoneSelector.fullscreenRequested
             }

            Components.Selector {
                id: zoneSelector
                config: mainDialog.config
                currentLayout: mainDialog.currentLayout
                highlightedZone: mainDialog.highlightedZone
            }

            // Advanced Edge Snapping Indicator
            Rectangle {
                id: edgeSnappingIndicator
                
                visible: (config.enableAdvancedEdgeSnapping && currentEdgeSnappingZone !== "") || (config.enableDebugLogging && moving)
                width: 280
                height: config.enableDebugLogging ? 280 : 50
                radius: 5
                color: Qt.rgba(0.1, 0.1, 0.1, 0.85)
                border.color: Qt.rgba(0.3, 0.7, 1.0, 1.0)
                border.width: 1
                
                // Position in the top-right corner
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    spacing: 4
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Layout: " + (currentLayout < config.layouts.length ? config.layouts[currentLayout].name : "Unknown")
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: currentEdgeSnappingZone || "No Zone Detected"
                        color: "white"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    
                    // Only show detailed debug info when debug logging is enabled
                    Rectangle {
                        visible: config.enableDebugLogging
                        width: parent.width
                        height: 1
                        color: "#444444"
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.5
                    }
                    
                    Text {
                        visible: config.enableDebugLogging
                        width: parent.width
                        text: "Cursor Position:"
                        color: "#88CCFF"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    
                    Text {
                        visible: config.enableDebugLogging
                        width: parent.width
                        text: "X: " + Workspace.cursorPos.x + ", Y: " + Workspace.cursorPos.y
                        color: "white"
                        font.pixelSize: 10
                    }
                    
                    Text {
                        visible: config.enableDebugLogging
                        width: parent.width
                        text: "Screen %: Left: " + (((Workspace.cursorPos.x - clientArea.x) / clientArea.width) * 100).toFixed(1) + 
                              "%, Top: " + (((Workspace.cursorPos.y - clientArea.y) / clientArea.height) * 100).toFixed(1) + "%"
                        color: "white"
                        font.pixelSize: 10
                    }
                    
                    Text {
                        visible: config.enableDebugLogging
                        width: parent.width
                        text: "From Edges: L: " + (((Workspace.cursorPos.x - clientArea.x) / clientArea.width) * 100).toFixed(1) + 
                              "%, R: " + (100 - (((Workspace.cursorPos.x - clientArea.x) / clientArea.width) * 100)).toFixed(1) + 
                              "%, T: " + (((Workspace.cursorPos.y - clientArea.y) / clientArea.height) * 100).toFixed(1) + 
                              "%, B: " + (100 - (((Workspace.cursorPos.y - clientArea.y) / clientArea.height) * 100)).toFixed(1) + "%"
                        color: "white"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                    
                    Rectangle {
                        visible: config.enableDebugLogging
                        width: parent.width
                        height: 1
                        color: "#444444"
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.5
                    }
                    
                    Text {
                        visible: config.enableDebugLogging
                        width: parent.width
                        text: "Zone Detection:"
                        color: "#88CCFF"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    
                    Text {
                        visible: config.enableDebugLogging
                        width: parent.width
                        text: "Current Zone: " + (mainDialog.currentZone || "None")
                        color: "#FFCC00"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    
                    Text {
                        visible: config.enableDebugLogging
                        width: parent.width
                        text: "Distance: " + (mainDialog.currentDistance || "None")
                        color: "#FFCC00"
                        font.pixelSize: 10
                    }
                    
                    Text {
                        visible: config.enableDebugLogging && moving
                        width: parent.width
                        text: "Moving Window: " + (Workspace.activeWindow ? (Workspace.activeWindow.resourceClass || "Unknown") : "None")
                        color: "#00FF88"
                        font.pixelSize: 10
                    }
                    
                    // Visual representation of the screen and zones
                    Rectangle {
                        visible: config.enableDebugLogging
                        width: parent.width
                        height: 80
                        color: "transparent"
                        border.color: "#444444"
                        border.width: 1
                        radius: 2
                        
                        // Screen representation
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            color: "transparent"
                            border.color: "#666666"
                            border.width: 1
                            
                            // Cursor position indicator
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: "#FFCC00"
                                x: (((Workspace.cursorPos.x - clientArea.x) / clientArea.width) * (parent.width - 6))
                                y: (((Workspace.cursorPos.y - clientArea.y) / clientArea.height) * (parent.height - 6))
                            }
                            
                            // Zone grid lines - horizontal thirds
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#444444"
                                y: parent.height * 0.33
                            }
                            
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#444444"
                                y: parent.height * 0.66
                            }
                            
                            // Zone grid lines - vertical sections
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#444444"
                                x: parent.width * 0.25
                            }
                            
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#444444"
                                x: parent.width * 0.5
                            }
                            
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#444444"
                                x: parent.width * 0.75
                            }
                            
                            // Highlight current zone if detected
                            Rectangle {
                                visible: mainDialog.currentZone !== ""
                                color: Qt.rgba(0.3, 0.7, 1.0, 0.3)
                                border.color: Qt.rgba(0.3, 0.7, 1.0, 0.8)
                                border.width: 1
                                
                                // Position and size based on zone type
                                x: getZoneX(mainDialog.currentZone) * parent.width
                                y: getZoneY(mainDialog.currentZone) * parent.height
                                width: getZoneWidth(mainDialog.currentZone) * parent.width
                                height: getZoneHeight(mainDialog.currentZone) * parent.height
                            }
                        }
                    }
                }
                
                // Add a subtle pulsing animation
                SequentialAnimation {
                    running: edgeSnappingIndicator.visible
                    loops: Animation.Infinite
                    
                    NumberAnimation {
                        target: edgeSnappingIndicator
                        property: "opacity"
                        from: 0.85
                        to: 1.0
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }
                    
                    NumberAnimation {
                        target: edgeSnappingIndicator
                        property: "opacity"
                        from: 1.0
                        to: 0.85
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }
                }
                
                // Helper functions to determine zone visualization
                function getZoneX(zoneName) {
                    if (!zoneName) return 0;
                    
                    if (zoneName.includes("left-edge") || zoneName.includes("left-top-edge") || zoneName.includes("left-bottom-edge")) {
                        return 0;
                    } else if (zoneName.includes("right-edge") || zoneName.includes("right-top-edge") || zoneName.includes("right-bottom-edge")) {
                        return 0.95;
                    } else if (zoneName.includes("left-top") || zoneName.includes("left-bottom") || zoneName.includes("left-center")) {
                        if (zoneName.includes("outer")) {
                            return 0.1;
                        } else {
                            return 0.25;
                        }
                    } else if (zoneName.includes("right-top") || zoneName.includes("right-bottom") || zoneName.includes("right-center")) {
                        if (zoneName.includes("outer")) {
                            return 0.75;
                        } else {
                            return 0.65;
                        }
                    } else if (zoneName.includes("center-top") || zoneName.includes("center-bottom") || zoneName === "zone-center") {
                        return 0.35;
                    }
                    
                    return 0;
                }
                
                function getZoneY(zoneName) {
                    if (!zoneName) return 0;
                    
                    if (zoneName.includes("top-edge") || zoneName.includes("left-top-edge") || zoneName.includes("right-top-edge")) {
                        return 0;
                    } else if (zoneName.includes("bottom-edge") || zoneName.includes("left-bottom-edge") || zoneName.includes("right-bottom-edge")) {
                        return 0.95;
                    } else if (zoneName.includes("top") && !zoneName.includes("edge")) {
                        return 0.05;
                    } else if (zoneName.includes("bottom") && !zoneName.includes("edge")) {
                        return 0.66;
                    } else if (zoneName.includes("center") || (zoneName.includes("left") && !zoneName.includes("top") && !zoneName.includes("bottom")) || 
                              (zoneName.includes("right") && !zoneName.includes("top") && !zoneName.includes("bottom"))) {
                        return 0.33;
                    }
                    
                    return 0;
                }
                
                function getZoneWidth(zoneName) {
                    if (!zoneName) return 0;
                    
                    if (zoneName.includes("edge")) {
                        return 0.05;
                    } else if (zoneName.includes("left") || zoneName.includes("right")) {
                        if (zoneName.includes("outer") || zoneName.includes("inner")) {
                            return 0.15;
                        } else {
                            return 0.35;
                        }
                    } else if (zoneName.includes("center")) {
                        return 0.3;
                    }
                    
                    return 0.1;
                }
                
                function getZoneHeight(zoneName) {
                    if (!zoneName) return 0;
                    
                    if (zoneName.includes("edge")) {
                        return 0.05;
                    } else if (zoneName.includes("top") || zoneName.includes("bottom")) {
                        if (zoneName.includes("edge")) {
                            return 0.05;
                        } else {
                            return 0.28;
                        }
                    } else if (zoneName.includes("center") || (zoneName.includes("left") && !zoneName.includes("top") && !zoneName.includes("bottom")) || 
                              (zoneName.includes("right") && !zoneName.includes("top") && !zoneName.includes("bottom"))) {
                        return 0.33;
                    }
                    
                    return 0.1;
                }
            }
        }

        // workspace connection
        Connections {
            target: Workspace

            function onWindowAdded(client) {
                if (!client) return;

                connectSignals(client);

                // check if client is in a zone application list
                config.layouts[currentLayout].zones.forEach((zone, zoneIndex) => {
                    if (zone.applications && client.resourceClass && zone.applications.includes(client.resourceClass.toString())) {
                        moveClientToZone(client, zoneIndex);
                        return;
                    }
                });

                // auto snap to closest zone
                if (config.autoSnapAllNew && checkFilter(client)) {
                    moveClientToClosestZone(client);
                }

                // check if new window spawns in a zone
                if (client.zone == undefined || client.zone == -1) matchZone(client);
            }
        }

        // options connection
        Connections {
            //! not working at the moment
            target: Options

            function onConfigChanged() {
                log("Config changed");
                mainDialog.loadConfig();
            }
        }

        // reusable timer
        Timer {
            id: delay

            function setTimeout(callback, timeout) {
                delay.interval = timeout;
                delay.repeat = false;
                delay.triggered.connect(callback);
                delay.triggered.connect(function release() {
                    delay.triggered.disconnect(callback);
                    delay.triggered.disconnect(release);
                });
                delay.start();
            }
        }
    }

    // Add this new function for enhanced point inside check
    function isPointInsideEnhanced(x, y, geometry, isAtVeryLeftEdge, isAtVeryRightEdge, isAtVeryTopEdge, isAtVeryBottomEdge) {
        // Standard check
        const standardCheck = x >= geometry.x && x <= geometry.x + geometry.width && 
                              y >= geometry.y && y <= geometry.y + geometry.height;
        
        // Special case for very edge positions
        if (isAtVeryLeftEdge && y >= geometry.y && y <= geometry.y + geometry.height && 
            Math.abs(x - geometry.x) < 10) {
            return true;
        }
        
        if (isAtVeryRightEdge && y >= geometry.y && y <= geometry.y + geometry.height && 
            Math.abs(x - (geometry.x + geometry.width)) < 10) {
            return true;
        }
        
        if (isAtVeryTopEdge && x >= geometry.x && x <= geometry.x + geometry.width && 
            Math.abs(y - geometry.y) < 10) {
            return true;
        }
        
        if (isAtVeryBottomEdge && x >= geometry.x && x <= geometry.x + geometry.width && 
            Math.abs(y - (geometry.y + geometry.height)) < 10) {
            return true;
        }
        
        return standardCheck;
    }
    
    // Function to handle advanced edge snapping
    function checkAdvancedEdgeSnapping(debugOnly = false) {
        if ((!config.enableAdvancedEdgeSnapping && !debugOnly) || !moving) return;
        
        try {
            /*
             * Zone Layout Diagram:
             * 
             * The screen is divided into edge zones and center zones:
             * 
             * Edge Zones (at screen edges, detected by distance from edge):
             * +------------------+------------------+------------------+
             * |                  |                  |                  |
             * | zone-left-top-   |  zone-left-top   |  zone-center-top | ... right zones
             * | edge             |                  |                  |
             * +------------------+------------------+------------------+
             * |                  |                  |                  |
             * | zone-left-edge   |                  |                  | ... right zones
             * |                  |                  |                  |
             * +------------------+------------------+------------------+
             * |                  |                  |                  |
             * | zone-left-bottom-|  zone-left-      |  zone-center-    | ... right zones
             * | edge             |  bottom          |  bottom          |
             * +------------------+------------------+------------------+
             * 
             * Center Zones (inside screen, away from edges):
             * +------------------+------------------+------------------+
             * |                  |                  |                  |
             * | zone-left-top-   | zone-left-top-   |  zone-center-top | ... right zones
             * | outer            | inner            |                  |
             * +------------------+------------------+------------------+
             * |                  |                  |                  |
             * | zone-left-center-| zone-left-center-|                  | 
             * | outer            | inner            |  zone-center     | ... right zones
             * |                  |                  |                  |
             * +------------------+------------------+------------------+
             * |                  |                  |                  |
             * | zone-left-bottom-| zone-left-bottom-|  zone-center-    | ... right zones
             * | outer            | inner            |  bottom          |
             * +------------------+------------------+------------------+
             * 
             * Horizontal boundaries:
             * - Edge zones: 0-5% (left edge), 35-65% (center), 95-100% (right edge)
             * - Center zones: 10-25% (left-outer), 25-35% (left-inner), 35-65% (center), 
             *                 65-75% (right-inner), 75-90% (right-outer)
             * 
             * Vertical boundaries:
             * - Edge zones: 0-5% (top edge), 95-100% (bottom edge)
             * - Center zones: 5-33% (top), 33-66% (center), 66-95% (bottom)
             */
            
            // Use the edge snapping layouts configuration from config
            const edgeSnappingConfig = config.edgeSnappingLayouts;
            
            if (!edgeSnappingConfig.zones || !edgeSnappingConfig.distances) {
                console.log("Invalid edge snapping configuration");
                return;
            }
            
            // Get screen dimensions
            const screenWidth = clientArea.width;
            const screenHeight = clientArea.height;
            const screenX = clientArea.x;
            const screenY = clientArea.y;
            
            // Get cursor position relative to screen
            const cursorX = Workspace.cursorPos.x - screenX;
            const cursorY = Workspace.cursorPos.y - screenY;
            
            // Calculate percentages from screen edges
            const percentFromLeft = (cursorX / screenWidth) * 100;
            const percentFromRight = 100 - percentFromLeft;
            const percentFromTop = (cursorY / screenHeight) * 100;
            const percentFromBottom = 100 - percentFromTop;
            
            // Determine which zone the cursor is in
            let currentZone = null;
            let currentDistance = null;
            
            // Get distances from configuration - these may have been customized by the user
            const distances = edgeSnappingConfig.distances;
            
            // Log the distances for debugging
            console.log("Using distances: far=[" + distances.far[0] + "," + distances.far[1] + 
                "], medium=[" + distances.medium[0] + "," + distances.medium[1] + 
                "], close=[" + distances.close[0] + "," + distances.close[1] + "]");
            
            // Log cursor position for debugging
            console.log("Cursor position: percentFromLeft=" + percentFromLeft.toFixed(2) + 
                        ", percentFromRight=" + percentFromRight.toFixed(2) + 
                        ", percentFromTop=" + percentFromTop.toFixed(2) + 
                        ", percentFromBottom=" + percentFromBottom.toFixed(2));
            
            // Check if cursor is in far distance from edge
            if (percentFromLeft <= distances.far[0] && percentFromLeft > distances.far[1]) {
                currentDistance = "far";
                if (percentFromTop <= distances.far[0] && percentFromTop > distances.far[1]) {
                    currentZone = "zone-left-top-edge";
                    console.log("Detected zone-left-top-edge (far): horizontal=[0," + distances.far[0] + "], vertical=[0," + distances.far[0] + "]");
                } else if (percentFromBottom <= distances.far[0] && percentFromBottom > distances.far[1]) {
                    currentZone = "zone-left-bottom-edge";
                    console.log("Detected zone-left-bottom-edge (far): horizontal=[0," + distances.far[0] + "], vertical=[" + (100-distances.far[0]) + ",100]");
                } else {
                    currentZone = "zone-left-edge";
                    console.log("Detected zone-left-edge (far): horizontal=[0," + distances.far[0] + "], vertical=[" + distances.far[0] + "," + (100-distances.far[0]) + "]");
                }
            } else if (percentFromRight <= distances.far[0] && percentFromRight > distances.far[1]) {
                currentDistance = "far";
                if (percentFromTop <= distances.far[0] && percentFromTop > distances.far[1]) {
                    currentZone = "zone-right-top-edge";
                    console.log("Detected zone-right-top-edge (far): horizontal=[" + (100-distances.far[0]) + ",100], vertical=[0," + distances.far[0] + "]");
                } else if (percentFromBottom <= distances.far[0] && percentFromBottom > distances.far[1]) {
                    currentZone = "zone-right-bottom-edge";
                    console.log("Detected zone-right-bottom-edge (far): horizontal=[" + (100-distances.far[0]) + ",100], vertical=[" + (100-distances.far[0]) + ",100]");
                } else {
                    currentZone = "zone-right-edge";
                    console.log("Detected zone-right-edge (far): horizontal=[" + (100-distances.far[0]) + ",100], vertical=[" + distances.far[0] + "," + (100-distances.far[0]) + "]");
                }
            } else if (percentFromTop <= distances.far[0] && percentFromTop > distances.far[1]) {
                currentDistance = "far";
                // Divide the top edge into three sections: left, center, right
                if (percentFromLeft <= 35) {
                    currentZone = "zone-left-top";
                    console.log("Detected zone-left-top (far): horizontal=[0,35], vertical=[0," + distances.far[0] + "]");
                } else if (percentFromRight <= 35) {
                    currentZone = "zone-right-top";
                    console.log("Detected zone-right-top (far): horizontal=[65,100], vertical=[0," + distances.far[0] + "]");
                } else {
                    currentZone = "zone-center-top";
                    console.log("Detected zone-center-top (far): horizontal=[35,65], vertical=[0," + distances.far[0] + "]");
                }
            } else if (percentFromBottom <= distances.far[0] && percentFromBottom > distances.far[1]) {
                currentDistance = "far";
                // Divide the bottom edge into three sections: left, center, right
                if (percentFromLeft <= 35) {
                    currentZone = "zone-left-bottom";
                    console.log("Detected zone-left-bottom (far): horizontal=[0,35], vertical=[" + (100-distances.far[0]) + ",100]");
                } else if (percentFromRight <= 35) {
                    currentZone = "zone-right-bottom";
                    console.log("Detected zone-right-bottom (far): horizontal=[65,100], vertical=[" + (100-distances.far[0]) + ",100]");
                } else {
                    currentZone = "zone-center-bottom";
                    console.log("Detected zone-center-bottom (far): horizontal=[35,65], vertical=[" + (100-distances.far[0]) + ",100]");
                }
            }
            
            // Check if cursor is in medium distance from edge
            if (!currentZone) {
                if (percentFromLeft <= distances.medium[0] && percentFromLeft > distances.medium[1]) {
                    currentDistance = "medium";
                    if (percentFromTop <= distances.medium[0] && percentFromTop > distances.medium[1]) {
                        currentZone = "zone-left-top-edge";
                        console.log("Detected zone-left-top-edge (medium): horizontal=[0," + distances.medium[0] + "], vertical=[0," + distances.medium[0] + "]");
                    } else if (percentFromBottom <= distances.medium[0] && percentFromBottom > distances.medium[1]) {
                        currentZone = "zone-left-bottom-edge";
                        console.log("Detected zone-left-bottom-edge (medium): horizontal=[0," + distances.medium[0] + "], vertical=[" + (100-distances.medium[0]) + ",100]");
                    } else {
                        currentZone = "zone-left-edge";
                        console.log("Detected zone-left-edge (medium): horizontal=[0," + distances.medium[0] + "], vertical=[" + distances.medium[0] + "," + (100-distances.medium[0]) + "]");
                    }
                } else if (percentFromRight <= distances.medium[0] && percentFromRight > distances.medium[1]) {
                    currentDistance = "medium";
                    if (percentFromTop <= distances.medium[0] && percentFromTop > distances.medium[1]) {
                        currentZone = "zone-right-top-edge";
                        console.log("Detected zone-right-top-edge (medium): horizontal=[" + (100-distances.medium[0]) + ",100], vertical=[0," + distances.medium[0] + "]");
                    } else if (percentFromBottom <= distances.medium[0] && percentFromBottom > distances.medium[1]) {
                        currentZone = "zone-right-bottom-edge";
                        console.log("Detected zone-right-bottom-edge (medium): horizontal=[" + (100-distances.medium[0]) + ",100], vertical=[" + (100-distances.medium[0]) + ",100]");
                    } else {
                        currentZone = "zone-right-edge";
                        console.log("Detected zone-right-edge (medium): horizontal=[" + (100-distances.medium[0]) + ",100], vertical=[" + distances.medium[0] + "," + (100-distances.medium[0]) + "]");
                    }
                } else if (percentFromTop <= distances.medium[0] && percentFromTop > distances.medium[1]) {
                    currentDistance = "medium";
                    // Divide the top edge into three sections: left, center, right
                    if (percentFromLeft <= 35) {
                        currentZone = "zone-left-top";
                        console.log("Detected zone-left-top (medium): horizontal=[0,35], vertical=[0," + distances.medium[0] + "]");
                    } else if (percentFromRight <= 35) {
                        currentZone = "zone-right-top";
                        console.log("Detected zone-right-top (medium): horizontal=[65,100], vertical=[0," + distances.medium[0] + "]");
                    } else {
                        currentZone = "zone-center-top";
                        console.log("Detected zone-center-top (medium): horizontal=[35,65], vertical=[0," + distances.medium[0] + "]");
                    }
                } else if (percentFromBottom <= distances.medium[0] && percentFromBottom > distances.medium[1]) {
                    currentDistance = "medium";
                    // Divide the bottom edge into three sections: left, center, right
                    if (percentFromLeft <= 35) {
                        currentZone = "zone-left-bottom";
                        console.log("Detected zone-left-bottom (medium): horizontal=[0,35], vertical=[" + (100-distances.medium[0]) + ",100]");
                    } else if (percentFromRight <= 35) {
                        currentZone = "zone-right-bottom";
                        console.log("Detected zone-right-bottom (medium): horizontal=[65,100], vertical=[" + (100-distances.medium[0]) + ",100]");
                    } else {
                        currentZone = "zone-center-bottom";
                        console.log("Detected zone-center-bottom (medium): horizontal=[35,65], vertical=[" + (100-distances.medium[0]) + ",100]");
                    }
                }
            }
            
            // Check if cursor is in close distance from edge
            if (!currentZone) {
                if (percentFromLeft <= distances.close[0] && percentFromLeft >= distances.close[1]) {
                    currentDistance = "close";
                    if (percentFromTop <= distances.close[0] && percentFromTop >= distances.close[1]) {
                        currentZone = "zone-left-top-edge";
                        console.log("Detected zone-left-top-edge (close): horizontal=[0," + distances.close[0] + "], vertical=[0," + distances.close[0] + "]");
                    } else if (percentFromBottom <= distances.close[0] && percentFromBottom >= distances.close[1]) {
                        currentZone = "zone-left-bottom-edge";
                        console.log("Detected zone-left-bottom-edge (close): horizontal=[0," + distances.close[0] + "], vertical=[" + (100-distances.close[0]) + ",100]");
                    } else {
                        currentZone = "zone-left-edge";
                        console.log("Detected zone-left-edge (close): horizontal=[0," + distances.close[0] + "], vertical=[" + distances.close[0] + "," + (100-distances.close[0]) + "]");
                    }
                } else if (percentFromRight <= distances.close[0] && percentFromRight >= distances.close[1]) {
                    currentDistance = "close";
                    if (percentFromTop <= distances.close[0] && percentFromTop >= distances.close[1]) {
                        currentZone = "zone-right-top-edge";
                        console.log("Detected zone-right-top-edge (close): horizontal=[" + (100-distances.close[0]) + ",100], vertical=[0," + distances.close[0] + "]");
                    } else if (percentFromBottom <= distances.close[0] && percentFromBottom >= distances.close[1]) {
                        currentZone = "zone-right-bottom-edge";
                        console.log("Detected zone-right-bottom-edge (close): horizontal=[" + (100-distances.close[0]) + ",100], vertical=[" + (100-distances.close[0]) + ",100]");
                    } else {
                        currentZone = "zone-right-edge";
                        console.log("Detected zone-right-edge (close): horizontal=[" + (100-distances.close[0]) + ",100], vertical=[" + distances.close[0] + "," + (100-distances.close[0]) + "]");
                    }
                } else if (percentFromTop <= distances.close[0] && percentFromTop >= distances.close[1]) {
                    currentDistance = "close";
                    // Divide the top edge into three sections: left, center, right
                    if (percentFromLeft <= 35) {
                        currentZone = "zone-left-top";
                        console.log("Detected zone-left-top (close): horizontal=[0,35], vertical=[0," + distances.close[0] + "]");
                    } else if (percentFromRight <= 35) {
                        currentZone = "zone-right-top";
                        console.log("Detected zone-right-top (close): horizontal=[65,100], vertical=[0," + distances.close[0] + "]");
                    } else {
                        currentZone = "zone-center-top";
                        console.log("Detected zone-center-top (close): horizontal=[35,65], vertical=[0," + distances.close[0] + "]");
                    }
                } else if (percentFromBottom <= distances.close[0] && percentFromBottom >= distances.close[1]) {
                    currentDistance = "close";
                    // Divide the bottom edge into three sections: left, center, right
                    if (percentFromLeft <= 35) {
                        currentZone = "zone-left-bottom";
                        console.log("Detected zone-left-bottom (close): horizontal=[0,35], vertical=[" + (100-distances.close[0]) + ",100]");
                    } else if (percentFromRight <= 35) {
                        currentZone = "zone-right-bottom";
                        console.log("Detected zone-right-bottom (close): horizontal=[65,100], vertical=[" + (100-distances.close[0]) + ",100]");
                    } else {
                        currentZone = "zone-center-bottom";
                        console.log("Detected zone-center-bottom (close): horizontal=[35,65], vertical=[" + (100-distances.close[0]) + ",100]");
                    }
                }
            }
            
            // Check center zones - only if we're not in any edge zone
            if (!currentZone) {
                // Get the fullscreen trigger distance as percentage of screen height
                const fullscreenValue = 7; // Default fullscreen trigger value in pixels
                const fullscreenPercentage = (fullscreenValue / screenHeight) * 100;
                
                // Calculate the center zone thresholds based on configured distances
                // Center zones horizontally begin from 25% and end with 75%
                
                // Horizontal thresholds
                const leftEdge = 25;
                const rightEdge = 75;
                const horizontalCenter = 50;
                const farDistance = distances.far[0]; // Use only the far distance for calculations
                
                // Vertical thresholds
                const topEdge = fullscreenPercentage; // Use fullscreen value for top
                const bottomEdge = 100; // Use 100% for bottom edge
                const topThird = 33;
                const bottomThird = 66;
                
                console.log("Center zone thresholds: horizontal=[" + 
                    "leftEdge=" + leftEdge + ", " +
                    "rightEdge=" + rightEdge + ", " +
                    "center=" + horizontalCenter + ", " +
                    "farDistance=" + farDistance + "], " +
                    "vertical=[" +
                    "topEdge=" + topEdge.toFixed(2) + ", " +
                    "bottomEdge=" + bottomEdge + ", " +
                    "topThird=" + topThird + ", " +
                    "bottomThird=" + bottomThird + "]");
                
                if (percentFromLeft > distances.close[0] && percentFromRight > distances.close[0] &&
                    percentFromTop > distances.close[0] && percentFromBottom > distances.close[0]) {
                    
                    // 1. Center zone
                    if (percentFromLeft >= horizontalCenter - farDistance && percentFromLeft <= horizontalCenter + farDistance &&
                        percentFromTop >= topThird && percentFromTop <= bottomThird) {
                        currentZone = "zone-center";
                        currentDistance = "close";
                        console.log("Detected zone-center: horizontal=[" + (horizontalCenter - farDistance) + 
                                   "," + (horizontalCenter + farDistance) + "], vertical=[" + topThird + "," + bottomThird + "]");
                    }
                    
                    // 2. Center-top zone
                    else if (percentFromLeft >= horizontalCenter - farDistance && percentFromLeft <= horizontalCenter + farDistance &&
                             percentFromTop > distances.close[0] && percentFromTop < topThird) {
                        currentZone = "zone-center-top";
                        currentDistance = "close";
                        console.log("Detected zone-center-top: horizontal=[" + (horizontalCenter - farDistance) + 
                                   "," + (horizontalCenter + farDistance) + "], vertical=[" + distances.close[0] + "," + topThird + "]");
                    }
                    
                    // LEFT SIDE ZONES
                    
                    // 3. Left-top-outer zone (at the outer left edge)
                    else if (percentFromLeft >= leftEdge - farDistance && percentFromLeft < leftEdge &&
                             percentFromTop > distances.close[0] && percentFromTop < topThird) {
                        currentZone = "zone-left-top-outer";
                        currentDistance = "close";
                        console.log("Detected zone-left-top-outer: horizontal=[" + (leftEdge - farDistance) + 
                                   "," + leftEdge + "], vertical=[" + distances.close[0] + "," + topThird + "]");
                    }
                    
                    // 4. Left-top-inner zone (between outer zone and center)
                    else if (percentFromLeft >= leftEdge && percentFromLeft < horizontalCenter - farDistance &&
                             percentFromTop > distances.close[0] && percentFromTop < topThird) {
                        currentZone = "zone-left-top-inner";
                        currentDistance = "close";
                        console.log("Detected zone-left-top-inner: horizontal=[" + leftEdge + 
                                   "," + (horizontalCenter - farDistance) + "], vertical=[" + distances.close[0] + "," + topThird + "]");
                    }
                    
                    // 5. Left-center-outer zone (at the outer left edge)
                    else if (percentFromLeft >= leftEdge - farDistance && percentFromLeft < leftEdge &&
                             percentFromTop >= topThird && percentFromTop <= bottomThird) {
                        currentZone = "zone-left-center-outer";
                        currentDistance = "close";
                        console.log("Detected zone-left-center-outer: horizontal=[" + (leftEdge - farDistance) + 
                                   "," + leftEdge + "], vertical=[" + topThird + "," + bottomThird + "]");
                    }
                    
                    // 6. Left-center-inner zone (between outer zone and center)
                    else if (percentFromLeft >= leftEdge && percentFromLeft < horizontalCenter - farDistance &&
                             percentFromTop >= topThird && percentFromTop <= bottomThird) {
                        currentZone = "zone-left-center-inner";
                        currentDistance = "close";
                        console.log("Detected zone-left-center-inner: horizontal=[" + leftEdge + 
                                   "," + (horizontalCenter - farDistance) + "], vertical=[" + topThird + "," + bottomThird + "]");
                    }
                    
                    // 7. Left-bottom-outer zone (at the outer left edge)
                    else if (percentFromLeft >= leftEdge - farDistance && percentFromLeft < leftEdge &&
                             percentFromTop > bottomThird && percentFromTop <= bottomEdge - distances.close[0]) {
                        currentZone = "zone-left-bottom-outer";
                        currentDistance = "close";
                        console.log("Detected zone-left-bottom-outer: horizontal=[" + (leftEdge - farDistance) + 
                                   "," + leftEdge + "], vertical=[" + bottomThird + "," + (bottomEdge - distances.close[0]) + "]");
                    }
                    
                    // 8. Left-bottom-inner zone (between outer zone and center)
                    else if (percentFromLeft >= leftEdge && percentFromLeft < horizontalCenter - farDistance &&
                             percentFromTop > bottomThird && percentFromTop <= bottomEdge - distances.close[0]) {
                        currentZone = "zone-left-bottom-inner";
                        currentDistance = "close";
                        console.log("Detected zone-left-bottom-inner: horizontal=[" + leftEdge + 
                                   "," + (horizontalCenter - farDistance) + "], vertical=[" + bottomThird + "," + (bottomEdge - distances.close[0]) + "]");
                    }
                    
                    // RIGHT SIDE ZONES
                    
                    // 9. Right-top-outer zone (at the outer right edge)
                    else if (percentFromLeft > rightEdge && percentFromLeft <= rightEdge + farDistance &&
                             percentFromTop > distances.close[0] && percentFromTop < topThird) {
                        currentZone = "zone-right-top-outer";
                        currentDistance = "close";
                        console.log("Detected zone-right-top-outer: horizontal=[" + rightEdge + 
                                   "," + (rightEdge + farDistance) + "], vertical=[" + distances.close[0] + "," + topThird + "]");
                    }
                    
                    // 10. Right-top-inner zone (between outer zone and center)
                    else if (percentFromLeft > horizontalCenter + farDistance && percentFromLeft <= rightEdge &&
                             percentFromTop > distances.close[0] && percentFromTop < topThird) {
                        currentZone = "zone-right-top-inner";
                        currentDistance = "close";
                        console.log("Detected zone-right-top-inner: horizontal=[" + (horizontalCenter + farDistance) + 
                                   "," + rightEdge + "], vertical=[" + distances.close[0] + "," + topThird + "]");
                    }
                    
                    // 11. Right-center-outer zone (at the outer right edge)
                    else if (percentFromLeft > rightEdge && percentFromLeft <= rightEdge + farDistance &&
                             percentFromTop >= topThird && percentFromTop <= bottomThird) {
                        currentZone = "zone-right-center-outer";
                        currentDistance = "close";
                        console.log("Detected zone-right-center-outer: horizontal=[" + rightEdge + 
                                   "," + (rightEdge + farDistance) + "], vertical=[" + topThird + "," + bottomThird + "]");
                    }
                    
                    // 12. Right-center-inner zone (between outer zone and center)
                    else if (percentFromLeft > horizontalCenter + farDistance && percentFromLeft <= rightEdge &&
                             percentFromTop >= topThird && percentFromTop <= bottomThird) {
                        currentZone = "zone-right-center-inner";
                        currentDistance = "close";
                        console.log("Detected zone-right-center-inner: horizontal=[" + (horizontalCenter + farDistance) + 
                                   "," + rightEdge + "], vertical=[" + topThird + "," + bottomThird + "]");
                    }
                    
                    // 13. Center-bottom zone
                    else if (percentFromLeft >= horizontalCenter - farDistance && percentFromLeft <= horizontalCenter + farDistance &&
                             percentFromTop > bottomThird && percentFromTop <= bottomEdge - distances.close[0]) {
                        currentZone = "zone-center-bottom";
                        currentDistance = "close";
                        console.log("Detected zone-center-bottom: horizontal=[" + (horizontalCenter - farDistance) + 
                                   "," + (horizontalCenter + farDistance) + "], vertical=[" + bottomThird + "," + (bottomEdge - distances.close[0]) + "]");
                    }
                    
                    // 14. Right-bottom-outer zone (at the outer right edge)
                    else if (percentFromLeft > rightEdge && percentFromLeft <= rightEdge + farDistance &&
                             percentFromTop > bottomThird && percentFromTop <= bottomEdge - distances.close[0]) {
                        currentZone = "zone-right-bottom-outer";
                        currentDistance = "close";
                        console.log("Detected zone-right-bottom-outer: horizontal=[" + rightEdge + 
                                   "," + (rightEdge + farDistance) + "], vertical=[" + bottomThird + "," + (bottomEdge - distances.close[0]) + "]");
                    }
                    
                    // 15. Right-bottom-inner zone (between outer zone and center)
                    else if (percentFromLeft > horizontalCenter + farDistance && percentFromLeft <= rightEdge &&
                             percentFromTop > bottomThird && percentFromTop <= bottomEdge - distances.close[0]) {
                        currentZone = "zone-right-bottom-inner";
                        currentDistance = "close";
                        console.log("Detected zone-right-bottom-inner: horizontal=[" + (horizontalCenter + farDistance) + 
                                   "," + rightEdge + "], vertical=[" + bottomThird + "," + (bottomEdge - distances.close[0]) + "]");
                    }
                    
                    // If we still don't have a zone, use the original center zone detection logic as fallback
                    if (!currentZone) {
                        // Divide the center into basic zones
                        if (percentFromLeft < 50 && percentFromTop < 50) {
                            // Top-left quadrant
                            if (percentFromLeft < 25) {
                                currentZone = "zone-left-top-outer";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-left-top-outer");
                            } else {
                                currentZone = "zone-left-top-inner";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-left-top-inner");
                            }
                        } else if (percentFromRight < 50 && percentFromTop < 50) {
                            // Top-right quadrant
                            if (percentFromRight < 25) {
                                currentZone = "zone-right-top-outer";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-right-top-outer");
                            } else {
                                currentZone = "zone-right-top-inner";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-right-top-inner");
                            }
                        } else if (percentFromLeft < 50 && percentFromBottom < 50) {
                            // Bottom-left quadrant
                            if (percentFromLeft < 25) {
                                currentZone = "zone-left-bottom-outer";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-left-bottom-outer");
                            } else {
                                currentZone = "zone-left-bottom-inner";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-left-bottom-inner");
                            }
                        } else if (percentFromRight < 50 && percentFromBottom < 50) {
                            // Bottom-right quadrant
                            if (percentFromRight < 25) {
                                currentZone = "zone-right-bottom-outer";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-right-bottom-outer");
                            } else {
                                currentZone = "zone-right-bottom-inner";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-right-bottom-inner");
                            }
                        } else {
                            // Pure center - check if we're closer to left/right or top/bottom
                            if (percentFromLeft < percentFromRight && percentFromLeft < 35) {
                                if (percentFromLeft < 25) {
                                    currentZone = "zone-left-center-outer";
                                    console.log("Fallback: Detected zone-left-center-outer");
                                } else {
                                    currentZone = "zone-left-center-inner";
                                    console.log("Fallback: Detected zone-left-center-inner");
                                }
                                currentDistance = "close";
                            } else if (percentFromRight < percentFromLeft && percentFromRight < 35) {
                                if (percentFromRight < 25) {
                                    currentZone = "zone-right-center-outer";
                                    console.log("Fallback: Detected zone-right-center-outer");
                                } else {
                                    currentZone = "zone-right-center-inner";
                                    console.log("Fallback: Detected zone-right-center-inner");
                                }
                                currentDistance = "close";
                            } else if (percentFromTop < percentFromBottom && percentFromTop < 33) {
                                currentZone = "zone-center-top";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-center-top");
                            } else if (percentFromBottom < percentFromTop && percentFromBottom < 33) {
                                currentZone = "zone-center-bottom";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-center-bottom");
                            } else {
                                currentZone = "zone-center";
                                currentDistance = "close";
                                console.log("Fallback: Detected zone-center");
                            }
                        }
                    }
                }
            }
            
            // If we found a zone and distance, check if there's a layout assigned to it
            if (currentZone && currentDistance) {
                console.log("Detected zone: " + currentZone + " with distance: " + currentDistance);
                
                // Update the main dialog properties for UI display
                mainDialog.currentZone = currentZone;
                mainDialog.currentDistance = currentDistance;
                
                // Check if the zone exists in the configuration
                if (edgeSnappingConfig.zones[currentZone]) {
                    console.log("Zone exists in configuration: " + currentZone);
                    
                    // Check if the distance exists for this zone
                    if (edgeSnappingConfig.zones[currentZone][currentDistance] !== undefined) {
                        console.log("Distance exists for zone: " + currentZone + "[" + currentDistance + "] = " + 
                                   edgeSnappingConfig.zones[currentZone][currentDistance]);
                        
                        const targetLayout = edgeSnappingConfig.zones[currentZone][currentDistance];
                        
                        // Update the current edge snapping zone with distance
                        currentEdgeSnappingZone = `${currentZone} (${currentDistance})`;
                        
                        // Only change layout if it's different from current and valid
                        if (targetLayout !== currentLayout && targetLayout < config.layouts.length) {
                            console.log("Advanced edge snapping: Changing to layout " + targetLayout + " from zone " + currentZone + " (" + currentDistance + ")");
                            setCurrentLayout(targetLayout);
                            
                            // Show OSD message
                            if (config.showOsdMessages) {
                                osdDbus.exec(config.trackLayoutPerScreen ? 
                                    `${config.layouts[currentLayout].name} (${Workspace.activeScreen.name}) - ${currentZone} (${currentDistance})` : 
                                    `${config.layouts[currentLayout].name} - ${currentZone} (${currentDistance})`);
                            }
                        } else {
                            console.log("Not changing layout: targetLayout=" + targetLayout + 
                                       ", currentLayout=" + currentLayout + 
                                       ", valid=" + (targetLayout < config.layouts.length));
                        }
                    } else {
                        console.log("Distance does not exist for zone: " + currentZone + "[" + currentDistance + "]");
                        // Clear the current edge snapping zone if no valid distance is detected
                        currentEdgeSnappingZone = "";
                    }
                } else {
                    console.log("Zone does not exist in configuration: " + currentZone);
                    // Clear the current edge snapping zone if no valid zone is detected
                    currentEdgeSnappingZone = "";
                }
            } else {
                // Clear the current edge snapping zone if no zone/distance is detected
                currentEdgeSnappingZone = "";
                mainDialog.currentZone = "";
                mainDialog.currentDistance = "";
            }
        } catch (e) {
            console.log("Error in advanced edge snapping: " + e.message);
        }
    }
}

