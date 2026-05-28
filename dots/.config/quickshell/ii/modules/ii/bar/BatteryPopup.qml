import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    ColumnLayout {
        id: columnLayout
        anchors {
            fill: parent
            margins: 14
        }
        spacing: 0

        // === HEADER ===
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: "BATTERY"
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Medium
                        letterSpacing: 1
                    }
                    color: Appearance.colors.colOutline
                }

                StyledText {
                    text: {
                        if (Battery.chargeState == 4) {
                            return Translation.tr("Fully charged");
                        } else if (Battery.chargeState == 1) {
                            return Translation.tr("Charging");
                        } else if (Battery.isPluggedIn) {
                            return Translation.tr("Not charging");
                        } else {
                            return Translation.tr("Discharging");
                        }
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOutline
                    opacity: 0.6
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: Appearance.font.pixelSize.title * 1.5
                height: width
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerHighest ?? Appearance.colors.colSurfaceVariant

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Battery.isCharging ? "battery_charging_full" : "battery_full"
                    fill: 0
                    font.weight: Font.Normal
                    iconSize: Appearance.font.pixelSize.small * 1.1
                    color: Appearance.colors.colOnSurface
                }
            }
        }

        // === PRIMARY VALUE ===
        StyledText {
            Layout.topMargin: 8
            text: `${Math.round(Battery.percentage * 100)}%`
            font {
                weight: Font.SemiBold
                pixelSize: Appearance.font.pixelSize.small * 2
            }
            color: Appearance.colors.colOnSurface
        }

        // === PROGRESS BAR ===
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 6
            height: 5

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.colors.colSurfaceContainerHighest ?? Appearance.colors.colSurfaceVariant
            }

            Rectangle {
                width: Math.max(parent.width * Math.max(Math.min(Battery.percentage, 1), Battery.percentage > 0 ? 0.05 : 0), height)
                height: parent.height
                radius: height / 2
                color: Appearance.colors.colPrimary
                opacity: 0.9
            }
        }

        // === DIVIDER ===
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 2
            height: 1
            color: Appearance.colors.colOutline
            opacity: 0.15
        }

        // === METRICS GRID ===
        GridLayout {
            id: gridLayout
            Layout.fillWidth: true
            Layout.topMargin: 8
            columns: 2
            rowSpacing: 8
            columnSpacing: 8
            uniformCellWidths: true

            WeatherCard {
                title: Translation.tr("Power draw")
                symbol: "bolt"
                value: `${Battery.energyRate.toFixed(2)}W`
            }
            WeatherCard {
                title: Translation.tr("Health")
                symbol: "heart_check"
                value: `${Battery.health.toFixed(1)}%`
            }
            WeatherCard {
                visible: {
                    let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                    let power = Battery.energyRate;
                    return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
                }
                title: Battery.isCharging ? Translation.tr("Time to full") : Translation.tr("Time to empty")
                symbol: "schedule"
                value: {
                    function formatTime(seconds) {
                        var h = Math.floor(seconds / 3600);
                        var m = Math.floor((seconds % 3600) / 60);
                        if (h > 0)
                            return `${h}h ${m}m`;
                        else
                            return `${m}m`;
                    }
                    if (Battery.isCharging)
                        return formatTime(Battery.timeToFull);
                    else
                        return formatTime(Battery.timeToEmpty);
                }
            }
            WeatherCard {
                visible: Battery.cycleCount > 0
                title: Translation.tr("Cycles")
                symbol: "autorenew"
                value: `${Battery.cycleCount}`
            }
        }
    }
}
