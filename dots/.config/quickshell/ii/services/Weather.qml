pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        wind: 0,
        windUnit: "km/h",
        windDirArrow: "↑",
        precip: 0,
        precipUnit: "mm",
        visib: 0,
        visibUnit: "km",
        press: 0,
        pressUnit: "hPa",
        temp: 0,
        tempFeelsLike: 0,
        lastRefresh: 0,
    })

    function windDirToArrow(dir) {
        const map = {
            "N": "↑", "NNE": "↗", "NE": "↗", "ENE": "→",
            "E": "→", "ESE": "↘", "SE": "↘", "SSE": "↓",
            "S": "↓", "SSW": "↙", "SW": "↙", "WSW": "←",
            "W": "←", "WNW": "↖", "NW": "↖", "NNW": "↑"
        };
        return map[dir] ?? "→";
    }

    function formatAstroTime(timeStr) {
        // API returns fixed 12h format like "04:50 AM" — convert to user's configured format
        const parts = timeStr.match(/(\d+):(\d+)\s*(AM|PM)/i);
        if (!parts) return timeStr;
        let hours = parseInt(parts[1]);
        const minutes = parseInt(parts[2]);
        const ampm = parts[3].toUpperCase();
        if (ampm === "PM" && hours !== 12) hours += 12;
        if (ampm === "AM" && hours === 12) hours = 0;
        const d = new Date();
        d.setHours(hours, minutes, 0, 0);
        return Qt.locale().toString(d, Config.options?.time.format ?? "hh:mm");
    }

    function refineData(data) {
        let temp = {};
        temp.uv = data?.current?.uvIndex || 0;
        temp.humidity = (data?.current?.humidity || 0) + "%";
        temp.sunrise = formatAstroTime(data?.astronomy?.sunrise || "12:00 AM");
        temp.sunset = formatAstroTime(data?.astronomy?.sunset || "12:00 AM");
        temp.windDir = data?.current?.winddir16Point || "N";
        temp.windDirArrow = windDirToArrow(temp.windDir);
        temp.wCode = data?.current?.weatherCode || "113";
        temp.city = data?.location?.areaName[0]?.value || "City";
        temp.temp = "";
        temp.tempFeelsLike = "";
        if (root.useUSCS) {
            temp.wind = data?.current?.windspeedMiles || 0;
            temp.windUnit = "mph";
            temp.precip = data?.current?.precipInches || 0;
            temp.precipUnit = "in";
            temp.visib = data?.current?.visibilityMiles || 0;
            temp.visibUnit = "mi";
            temp.press = data?.current?.pressureInches || 0;
            temp.pressUnit = "psi";
            temp.temp += (data?.current?.temp_F || 0);
            temp.tempFeelsLike += (data?.current?.FeelsLikeF || 0);
            temp.temp += "°F";
            temp.tempFeelsLike += "°F";
        } else {
            temp.wind = data?.current?.windspeedKmph || 0;
            temp.windUnit = "km/h";
            temp.precip = data?.current?.precipMM || 0;
            temp.precipUnit = "mm";
            temp.visib = data?.current?.visibility || 0;
            temp.visibUnit = "km";
            temp.press = data?.current?.pressure || 0;
            temp.pressUnit = "hPa";
            temp.temp += (data?.current?.temp_C || 0);
            temp.tempFeelsLike += (data?.current?.FeelsLikeC || 0);
            temp.temp += "°C";
            temp.tempFeelsLike += "°C";
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function getData() {
        const location = root.gpsActive && root.location.valid
            ? `${root.location.lat},${root.location.lon}`
            : root.city.trim();
        fetcher.command = [
            "curl", "--fail", "--silent", "--show-error", "--globoff",
            "--connect-timeout", "10", "--max-time", "20",
            `https://wttr.in/${encodeURIComponent(location)}?format=j1`
        ];
        fetcher.running = true;
    }

    Component.onCompleted: {
        if (!root.gpsActive) return;
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    Process {
        id: fetcher
        stdout: StdioCollector { id: weatherOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                console.error(`[WeatherService] Fetch failed (exit ${exitCode}, status ${exitStatus})`);
                return;
            }
            try {
                const parsedData = JSON.parse(weatherOutput.text);
                const current = parsedData?.current_condition?.[0];
                const location = parsedData?.nearest_area?.[0];
                const astronomy = parsedData?.weather?.[0]?.astronomy?.[0];
                if (!current || !location || !astronomy)
                    throw new Error("Incomplete weather response");
                root.refineData({ current, location, astronomy });
            } catch (e) {
                console.error(`[WeatherService] ${e.message}`);
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            // update the location if the given location is valid
            // if it fails getting the location, use the last valid location
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.lon = position.coordinate.longitude;
                root.location.valid = true;
                // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
                root.getData();
                // if can't get initialized with valid location deactivate the GPS
            } else {
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get the GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using the fallback method instead."), "-a", "Shell"]);
                console.error("[WeatherService] Could not aquire a valid backend plugin.");
            }
        }
    }

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
