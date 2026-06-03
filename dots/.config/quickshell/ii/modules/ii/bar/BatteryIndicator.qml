import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitWidth: batteryIcon.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    MaterialSymbol {
        id: batteryIcon
        anchors.centerIn: parent
        fill: 1
        text: {
            if (isLow && !isCharging) return "battery_android_alert";
            if (isPluggedIn) return "battery_android_bolt";
            if (percentage >= 1) return "battery_android_full";
            const level = Math.round(percentage * 6);
            return `battery_android_${level}`;
        }
        iconSize: Appearance.font.pixelSize.title
        color: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSecondaryContainer
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
