import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.calendar
import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    visible: true
    color: "transparent"

    implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    Component.onCompleted: {
        GlobalFocusGrab.addDismissable(root)
    }
    Component.onDestruction: {
        GlobalFocusGrab.removeDismissable(root)
    }

    Connections {
        target: GlobalFocusGrab

        function onDismissed() {
            GlobalStates.clockWidgetOpen = false
        }
    }

    StyledRectangularShadow {
        target: popupBackground
    }

    Rectangle {
        id: popupBackground
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        implicitWidth: columnLayout.implicitWidth + 20
        implicitHeight: columnLayout.implicitHeight + 20
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        clip: true

        ColumnLayout {
            id: columnLayout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            StyledPopupHeaderRow {
                icon: "calendar_month"
                label: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
            }

            CalendarWidget {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            StyledPopupValueRow {
                icon: "timelapse"
                label: Translation.tr("System uptime:")
                value: DateTime.uptime
            }
        }
    }
}
