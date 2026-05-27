import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope

    property bool dontAutoCancelSearch: false

    PanelWindow {
        id: panelWindow

        property string searchingText: ""
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: Hyprland.focusedMonitor?.id == monitor?.id

        property bool exitAnimating: false
        Timer {
            id: exitAnimTimer
            interval: 130 // slightly longer than slideOut duration (100)
            onTriggered: panelWindow.exitAnimating = false
        }

        visible: GlobalStates.overviewOpen || panelWindow.exitAnimating

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        color: "transparent"

        mask: Region {
            item: (GlobalStates.overviewOpen || panelWindow.exitAnimating) ? contentItem : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        implicitWidth: contentItem.implicitWidth
        implicitHeight: contentItem.implicitHeight

        Connections {
            target: GlobalStates

            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    panelWindow.exitAnimating = true
                    exitAnimTimer.restart()
                    searchWidget.disableExpandAnimation()
                    overviewScope.dontAutoCancelSearch = false
                    GlobalFocusGrab.dismiss()
                } else {
                    panelWindow.exitAnimating = false
                    exitAnimTimer.stop()
                    if (!overviewScope.dontAutoCancelSearch) {
                        searchWidget.cancelSearch()
                    }

                    GlobalFocusGrab.addDismissable(panelWindow)
                }
            }
        }

        Connections {
            target: GlobalFocusGrab

            function onDismissed() {
                GlobalStates.overviewOpen = false
            }
        }

        function setSearchingText(text) {
            searchWidget.setSearchingText(text)
            searchWidget.focusFirstItem()
        }

        Item {
            id: contentItem

            anchors.fill: parent

            MouseArea {
                anchors.fill: parent

                onClicked: GlobalStates.overviewOpen = false
            }

            Item {
                id: searchWidgetWrapper

                implicitWidth: contentItem.implicitWidth
                implicitHeight: contentItem.implicitHeight

                z: 999

                readonly property real slideOffset: -(implicitHeight + 100)

                property real slideY: slideOffset
                property real slideOpacity: 0.0

                opacity: slideOpacity

                transform: Translate {
                    y: searchWidgetWrapper.slideY
                }

                Timer {
                    id: slideInStartTimer

                    interval: 16
                    repeat: false

                    onTriggered: {
                        slideInYAnim.from = searchWidgetWrapper.slideOffset
                        slideInYAnim.to = 0

                        slideInOpacityAnim.from = 0.0
                        slideInOpacityAnim.to = 1.0

                        slideInParallel.start()
                    }
                }

                function triggerSlideIn() {
                    slideOutParallel.stop()
                    slideInParallel.stop()
                    slideInStartTimer.stop()

                    searchWidgetWrapper.slideY = searchWidgetWrapper.slideOffset
                    searchWidgetWrapper.slideOpacity = 0.0

                    slideInStartTimer.start()
                }

                function triggerSlideOut() {
                    slideInParallel.stop()

                    slideOutYAnim.from = searchWidgetWrapper.slideY
                    slideOutYAnim.to = searchWidgetWrapper.slideOffset

                    slideOutOpacityAnim.from = searchWidgetWrapper.slideOpacity
                    slideOutOpacityAnim.to = 0.0

                    slideOutParallel.start()
                }

                ParallelAnimation {
                    id: slideInParallel

                    NumberAnimation {
                        id: slideInYAnim

                        target: searchWidgetWrapper
                        property: "slideY"

                        duration: 200

                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                    }

                    NumberAnimation {
                        id: slideInOpacityAnim

                        target: searchWidgetWrapper
                        property: "slideOpacity"

                        duration: 200

                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                    }
                }

                ParallelAnimation {
                    id: slideOutParallel

                    NumberAnimation {
                        id: slideOutYAnim

                        target: searchWidgetWrapper
                        property: "slideY"

                        duration: 100

                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
                    }

                    NumberAnimation {
                        id: slideOutOpacityAnim

                        target: searchWidgetWrapper
                        property: "slideOpacity"

                        duration: 100

                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
                    }
                }

                Connections {
                    target: panelWindow

                    function onVisibleChanged() {
                        if (panelWindow.visible && GlobalStates.overviewOpen) {
                            searchWidgetWrapper.triggerSlideIn()
                        }
                    }
                }

                Connections {
                    target: GlobalStates

                    function onOverviewOpenChanged() {
                        if (GlobalStates.overviewOpen) {
                            if (panelWindow.visible) {
                                searchWidgetWrapper.triggerSlideIn()
                            }
                        } else {
                            searchWidgetWrapper.triggerSlideOut()
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false
                    }
                }

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top

                    topMargin: Appearance.sizes.elevationMargin
                        + (Config.options.bar.vertical
                            ? 0
                            : (Appearance.sizes.barHeight ?? 0))
                }

                SearchWidget {
                    id: searchWidget

                    anchors.horizontalCenter: parent.horizontalCenter

                    Synchronizer on searchingText {
                        property alias source: panelWindow.searchingText
                    }
                }
            }

            Loader {
                id: overviewLoader

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: searchWidgetWrapper.bottom
                anchors.topMargin: -8

                active: GlobalStates.overviewOpen
                    && (Config?.options.overview.enable ?? true)

                sourceComponent: OverviewWidget {
                    screen: panelWindow.screen
                    visible: panelWindow.searchingText == ""
                }
            }
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false
            return
        }

        overviewScope.dontAutoCancelSearch = true

        panelWindow.setSearchingText(Config.options.search.prefix.clipboard)

        GlobalStates.overviewOpen = true
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false
            return
        }

        overviewScope.dontAutoCancelSearch = true

        panelWindow.setSearchingText(Config.options.search.prefix.emojis)

        GlobalStates.overviewOpen = true
    }

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }

        function workspacesToggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }

        function close() {
            GlobalStates.overviewOpen = false
        }

        function open() {
            GlobalStates.overviewOpen = true
        }

        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false
        }

        function clipboardToggle() {
            overviewScope.toggleClipboard()
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"

        onPressed: {
            GlobalStates.overviewOpen = false
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description:
            "Toggles search on release"

            + "This is necessary because GlobalShortcut.onReleased in quickshell "
            + "triggers whether or not you press something else while holding the key. "

            + "To make sure this works consistently, use binditn = MODKEYS, "
            + "catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true
                return
            }

            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }

    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"

        description:
            "Interrupts possibility of search being toggled on release. "

            + "This is necessary because GlobalShortcut.onReleased in quickshell "
            + "triggers whether or not you press something else while holding the key. "

            + "To make sure this works consistently, use binditn = MODKEYS, "
            + "catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false
        }
    }

    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard()
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis()
        }
    }
}
