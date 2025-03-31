import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Dialogs

import "./components" as Components
import "./config.js" as ConfigJS

Item {
    id: root
    
    Component.onCompleted: {
        // Initialize controls state
        ConfigJS.setupAdvancedEdgeSnappingControls(
            kcfg_enableEdgeSnapping, 
            kcfg_enableAdvancedEdgeSnapping, 
            kcfg_edgeSnappingTriggerDistance
        );
    }

    // Find the objects by ID from the UI file
    function findObject(objectName) {
        return root.findChild(objectName);
    }

    // These are the actual controls from the UI file
    property var kcfg_enableEdgeSnapping: findObject("kcfg_enableEdgeSnapping")
    property var kcfg_enableAdvancedEdgeSnapping: findObject("kcfg_enableAdvancedEdgeSnapping")
    property var kcfg_edgeSnappingTriggerDistance: findObject("kcfg_edgeSnappingTriggerDistance")
} 