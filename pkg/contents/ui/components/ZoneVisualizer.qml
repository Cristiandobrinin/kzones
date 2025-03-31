import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: visualizer
    
    property bool centerZonesEnabled: false
    
    color: Qt.rgba(0.1, 0.1, 0.1, 0.9)
    radius: 4
    border.color: Qt.rgba(0.3, 0.3, 0.3, 1)
    border.width: 1
    
    // Title at the top of the visualizer
    Text {
        id: title
        text: "Screen Zone Map"
        color: "white"
        font.pixelSize: 12
        font.bold: true
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
    }
    
    // Edge zones - always active
    // Left edge
    ZoneRect {
        id: leftEdge
        anchors.left: parent.left
        anchors.top: title.bottom
        anchors.topMargin: 15
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        width: parent.width * 0.05
        color: Kirigami.Theme.negativeTextColor
        opacity: 0.7
        zoneText: "L"
    }
    
    // Right edge
    ZoneRect {
        id: rightEdge
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.topMargin: 15
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        width: parent.width * 0.05
        color: Kirigami.Theme.negativeTextColor
        opacity: 0.7
        zoneText: "R"
    }
    
    // Top edge
    ZoneRect {
        id: topEdge
        anchors.top: title.bottom
        anchors.topMargin: 15
        anchors.left: leftEdge.right
        anchors.right: rightEdge.left
        height: parent.height * 0.05
        color: Kirigami.Theme.neutralTextColor
        opacity: 0.7
        zoneText: "Top"
    }
    
    // Bottom edge
    ZoneRect {
        id: bottomEdge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        anchors.left: leftEdge.right
        anchors.right: rightEdge.left
        height: parent.height * 0.05
        color: Kirigami.Theme.neutralTextColor
        opacity: 0.7
        zoneText: "Bottom"
    }
    
    // Corner zones
    // Top left corner
    ZoneRect {
        id: topLeftCorner
        anchors.left: parent.left
        anchors.top: title.bottom
        anchors.topMargin: 15
        width: parent.width * 0.05
        height: parent.height * 0.05
        color: Kirigami.Theme.neutralTextColor
        opacity: 0.7
        zoneText: "TL"
    }
    
    // Top right corner
    ZoneRect {
        id: topRightCorner
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.topMargin: 15
        width: parent.width * 0.05
        height: parent.height * 0.05
        color: Kirigami.Theme.neutralTextColor
        opacity: 0.7
        zoneText: "TR"
    }
    
    // Bottom left corner
    ZoneRect {
        id: bottomLeftCorner
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        width: parent.width * 0.05
        height: parent.height * 0.05
        color: Kirigami.Theme.neutralTextColor
        opacity: 0.7
        zoneText: "BL"
    }
    
    // Bottom right corner
    ZoneRect {
        id: bottomRightCorner
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        width: parent.width * 0.05
        height: parent.height * 0.05
        color: Kirigami.Theme.neutralTextColor
        opacity: 0.7
        zoneText: "BR"
    }
    
    // Center zones - conditionally visible
    // Center zone
    ZoneRect {
        id: centerZone
        anchors.centerIn: parent
        width: parent.width * 0.3
        height: parent.height * 0.3
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.7 : 0.2
        zoneText: "Center"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    // Left center zones
    ZoneRect {
        id: leftCenterOuter
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: leftEdge.right
        width: parent.width * 0.15
        height: parent.height * 0.3
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "L-Out"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: leftCenterInner
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: leftCenterOuter.right
        width: parent.width * 0.10
        height: parent.height * 0.3
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "L-In"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    // Right center zones
    ZoneRect {
        id: rightCenterOuter
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: rightEdge.left
        width: parent.width * 0.15
        height: parent.height * 0.3
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "R-Out"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: rightCenterInner
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: rightCenterOuter.left
        width: parent.width * 0.10
        height: parent.height * 0.3
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "R-In"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    // Add corner zones
    // Top zones
    ZoneRect {
        id: leftTopOuter
        anchors.top: topEdge.bottom
        anchors.left: leftEdge.right
        width: parent.width * 0.15
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "LT-Out"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: leftTopInner
        anchors.top: topEdge.bottom
        anchors.left: leftTopOuter.right
        width: parent.width * 0.10
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "LT-In"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: rightTopInner
        anchors.top: topEdge.bottom
        anchors.right: rightTopOuter.left
        width: parent.width * 0.10
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "RT-In"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: rightTopOuter
        anchors.top: topEdge.bottom
        anchors.right: rightEdge.left
        width: parent.width * 0.15
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "RT-Out"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    // Bottom zones
    ZoneRect {
        id: leftBottomOuter
        anchors.bottom: bottomEdge.top
        anchors.left: leftEdge.right
        width: parent.width * 0.15
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "LB-Out"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: leftBottomInner
        anchors.bottom: bottomEdge.top
        anchors.left: leftBottomOuter.right
        width: parent.width * 0.10
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "LB-In"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: rightBottomInner
        anchors.bottom: bottomEdge.top
        anchors.right: rightBottomOuter.left
        width: parent.width * 0.10
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "RB-In"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    ZoneRect {
        id: rightBottomOuter
        anchors.bottom: bottomEdge.top
        anchors.right: rightEdge.left
        width: parent.width * 0.15
        height: parent.height * 0.15
        color: Kirigami.Theme.visitedLinkColor
        opacity: centerZonesEnabled ? 0.6 : 0.15
        zoneText: "RB-Out"
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            radius: 4
            visible: !centerZonesEnabled
        }
    }
    
    // Bottom label to indicate keyboard shortcut
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 5
        text: "Toggle center zones with Alt+Z"
        color: "white"
        font.pixelSize: 10
    }
    
    // Component to represent zones
    component ZoneRect: Rectangle {
        property string zoneText: ""
        
        radius: 4
        
        Text {
            anchors.centerIn: parent
            text: zoneText
            color: "white"
            font.pixelSize: 10
            font.bold: true
        }
    }
} 