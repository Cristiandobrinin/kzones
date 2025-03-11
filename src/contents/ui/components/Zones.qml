import QtQuick
import QtQuick.Layouts

import "../components" as Components

Item {
    id: zones

    property var config
    property int currentLayout
    property int highlightedZone
    property bool fullscreenRequested: false
    property int effectiveLayout: fullscreenRequested ? config.fullscreenLayoutIndex : currentLayout

    property alias repeater: repeater

    Repeater {
        id: repeater

        model: config.layouts[effectiveLayout].zones

        // zone
        Item {
            id: zone

            property int zoneIndex: index
            property int zonePadding: config.layouts[effectiveLayout].padding || 0
            property var renderZones: config.zoneOverlayIndicatorDisplay == 1 ? [config.layouts[effectiveLayout].zones[index]] : config.layouts[effectiveLayout].zones
            property int activeIndex: config.zoneOverlayIndicatorDisplay == 1 ? 0 : index
            property var indicatorPos: modelData?.indicator?.position || "center"

            x: ((modelData.x / 100) * (clientArea.width - zonePadding)) + zonePadding
            y: ((modelData.y / 100) * (clientArea.height - zonePadding)) + zonePadding
            implicitWidth: ((modelData.width / 100) * (clientArea.width - zonePadding)) - zonePadding
            implicitHeight: ((modelData.height / 100) * (clientArea.height - zonePadding)) - zonePadding

            // zone indicator
            Rectangle {
                id: zoneIndicator

                width: 160
                height: 100
                color: colorHelper.backgroundColor
                radius: 10
                border.color: colorHelper.getBorderColor(color)
                border.width: 1
                opacity: !fullscreenRequested && (!showZoneOverlay ? 0 : (zoneSelector.expanded) ? 0 : (highlightedZone == zoneIndex ? 0.6 : 1))
                scale: highlightedZone == zoneIndex ? 1.1 : 1
                visible: config.enableZoneOverlay && !fullscreenRequested

                // position
                anchors.left: (indicatorPos === "top-left" || indicatorPos === "left-center" || indicatorPos === "bottom-left") ? parent.left : undefined
                anchors.right: (indicatorPos === "top-right" || indicatorPos === "right-center" || indicatorPos === "bottom-right") ? parent.right : undefined
                anchors.top: (indicatorPos === "top-left" || indicatorPos === "top-center" || indicatorPos === "top-right") ? parent.top : undefined
                anchors.bottom: (indicatorPos === "bottom-left" || indicatorPos === "bottom-center" || indicatorPos === "bottom-right") ? parent.bottom : undefined
                anchors.horizontalCenter: (indicatorPos === "center" || indicatorPos === "top-center" || indicatorPos === "bottom-center") ? parent.horizontalCenter : undefined
                anchors.verticalCenter: (indicatorPos === "center" || indicatorPos === "left-center" || indicatorPos === "right-center") ? parent.verticalCenter : undefined

                // margin
                anchors.leftMargin: modelData?.indicator?.margin?.left || 0
                anchors.rightMargin: modelData?.indicator?.margin?.right || 0
                anchors.topMargin: modelData?.indicator?.margin?.top || 0
                anchors.bottomMargin: modelData?.indicator?.margin?.bottom || 0

                // offset
                anchors.horizontalCenterOffset: (modelData?.indicator?.margin?.left || 0) - (modelData?.indicator?.margin?.right || 0)
                anchors.verticalCenterOffset: (modelData?.indicator?.margin?.top || 0) - (modelData?.indicator?.margin?.bottom || 0)


                Behavior on scale {
                    NumberAnimation {
                        duration: zoneSelector.expanded ? 0 : 150
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Components.Indicator {
                    zones: renderZones
                    activeZone: activeIndex
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: parent.height - 20
                    hovering: (highlightedZone == zoneIndex)
                }
            }

            // zone border
            Rectangle {
                id: zoneBorder
                anchors.fill: parent
                color: "transparent"
                border.color: (highlightedZone == zoneIndex) ? modelData.color || colorHelper.accentColor : "transparent"
                border.width: fullscreenRequested ? 3 : 2
                radius: 8
                opacity: (highlightedZone == zoneIndex) ? 1 : 0
                
                // Add a pulsing animation for fullscreen mode
                SequentialAnimation {
                    running: fullscreenRequested && highlightedZone == zoneIndex
                    loops: Animation.Infinite
                    
                    NumberAnimation {
                        target: zoneBorder
                        property: "border.width"
                        from: 3
                        to: 5
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                    
                    NumberAnimation {
                        target: zoneBorder
                        property: "border.width"
                        from: 5
                        to: 3
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            // zone background
            Rectangle {
                id: zoneBackground
                opacity: (highlightedZone == zoneIndex) ? (fullscreenRequested ? 0.2 : 0.1) : 0
                anchors.fill: parent
                color: modelData.color || colorHelper.accentColor
                radius: 8
                
                // Add a subtle pulsing animation for fullscreen mode
                SequentialAnimation {
                    running: fullscreenRequested && highlightedZone == zoneIndex
                    loops: Animation.Infinite
                    
                    NumberAnimation {
                        target: zoneBackground
                        property: "opacity"
                        from: 0.2
                        to: 0.3
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                    
                    NumberAnimation {
                        target: zoneBackground
                        property: "opacity"
                        from: 0.3
                        to: 0.2
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            // indicator shadow
            Components.Shadow {
                target: zoneIndicator
                visible: zoneIndicator.visible
            }

            Components.ColorHelper {
                id: colorHelper
            }
        }
    }
}