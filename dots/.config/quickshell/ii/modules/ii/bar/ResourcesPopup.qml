import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    component IconBox: Rectangle {
        property string icon: ""

        width: Appearance.font.pixelSize.title * 1.5
        height: width
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainerHighest ?? Appearance.colors.colSurfaceVariant
        Layout.alignment: Qt.AlignVCenter

        MaterialSymbol {
            anchors.centerIn: parent
            text: parent.icon
            fill: 0
            iconSize: Appearance.font.pixelSize.small * 1.1
            color: Appearance.colors.colOnSurface
        }
    }

    component PillBadge: Rectangle {
        property string badgeText: ""

        radius: height / 2
        color: Appearance.colors.colSurfaceContainerHighest ?? Appearance.colors.colSurfaceVariant
        implicitWidth: pillLabel.implicitWidth + 16
        implicitHeight: pillLabel.implicitHeight + 6
        Layout.alignment: Qt.AlignVCenter

        StyledText {
            id: pillLabel
            anchors.centerIn: parent
            text: parent.badgeText
            font {
                pixelSize: Appearance.font.pixelSize.smaller
                weight: Font.Normal
            }
            color: Appearance.colors.colOutline
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Appearance.colors.colOutline
        opacity: 0.15
    }

    component MemoryCard: ColumnLayout {
        id: memCard

        property string label: ""
        property string icon: ""
        property real used: 0
        property real total: 0

        readonly property real pct: total > 0 ? used / total : 0

        visible: total > 0
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            spacing: 8

            IconBox { icon: memCard.icon }

            StyledText {
                text: memCard.label
                font {
                    pixelSize: Appearance.font.pixelSize.small
                    weight: Font.Bold
                }
                color: Appearance.colors.colOnSurface
            }

            Item { Layout.fillWidth: true }

            PillBadge {
                badgeText: `${Math.round(memCard.pct * 100)}% · ${(memCard.used / (1024 * 1024)).toFixed(1)} / ${(memCard.total / (1024 * 1024)).toFixed(1)} GB`
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: memCard.pct
            valueBarHeight: 5
            wavy: true
            waveAmplitudeMultiplier: 0.45
            highlightColor: Appearance.colors.colPrimary
            trackColor: Appearance.colors.colSurfaceContainerHighest ?? Appearance.colors.colSurfaceVariant
        }
    }

    Item {
        anchors.centerIn: parent
        implicitWidth: contentColumn.implicitWidth + 8
        implicitHeight: contentColumn.implicitHeight + 8

        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 0

        // === HEADER ===
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: "SYSTEM"
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Bold
                        letterSpacing: 1
                    }
                    color: "white"
                }

                StyledText {
                    text: "All nominal"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOutline
                    opacity: 0.6
                }
            }

            Item { Layout.fillWidth: true }

            IconBox { icon: "computer" }
        }

        // Header → CPU spacing
        Item { implicitHeight: 12 }

        // === CPU ===
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconBox { icon: "speed" }

            StyledText {
                text: "CPU"
                font {
                    pixelSize: Appearance.font.pixelSize.small
                    weight: Font.Bold
                }
                color: Appearance.colors.colOnSurface
            }

            Item { Layout.fillWidth: true }

            PillBadge {
                badgeText: `${Math.round(ResourceUsage.cpuUsage * 100)}% · ${Math.round(ResourceUsage.cpuTemp)}°C`
            }
        }

        Item { implicitHeight: 8 }

        StyledProgressBar {
            Layout.fillWidth: true
            value: ResourceUsage.cpuUsage
            valueBarHeight: 5
            wavy: true
            waveAmplitudeMultiplier: 0.45
            highlightColor: Appearance.colors.colPrimary
            trackColor: Appearance.colors.colSurfaceContainerHighest ?? Appearance.colors.colSurfaceVariant
        }

        // CPU → RAM divider
        Item { implicitHeight: 10 }
        Divider {}
        Item { implicitHeight: 10 }

        // === RAM ===
        MemoryCard {
            label: "RAM"
            icon: "memory"
            used: ResourceUsage.memoryUsed
            total: ResourceUsage.memoryTotal
        }

        // RAM → Swap divider
        Item { implicitHeight: 10 }
        Divider {}
        Item { implicitHeight: 10 }

        // === SWAP ===
        MemoryCard {
            label: "Swap"
            icon: "swap_horiz"
            used: ResourceUsage.swapUsed
            total: ResourceUsage.swapTotal
        }

        // Swap → Disk divider
        Item { implicitHeight: 10 }
        Divider {}
        Item { implicitHeight: 10 }

        // === DISK ===
        MemoryCard {
            label: "Disk"
            icon: "hard_drive"
            used: ResourceUsage.diskUsed
            total: ResourceUsage.diskTotal
        }

        Item { implicitHeight: 6 }
        }
    }
}
