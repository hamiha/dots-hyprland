pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    // Convenient stuff

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    // Internals

    property bool clientsDirty: false
    property bool monitorsDirty: false
    property bool layersDirty: false
    property bool workspacesDirty: false
    property bool activeWorkspaceDirty: false

    readonly property list<string> clientWorkspaceEvents: [
        "openwindow", "closewindow", "kill", "movewindow", "movewindowv2"
    ]
    // ponytail: Unused workspace metadata like hasfullscreen/lastwindow may lag; refresh it if UI starts consuming it.
    readonly property list<string> clientEvents: [
        "activewindow", "activewindowv2", "fullscreen", "windowtitle", "windowtitlev2",
        "changefloatingmode", "urgent", "togglegroup", "moveintogroup", "moveoutofgroup", "pin", "minimized"
    ]
    readonly property list<string> activeWorkspaceEvents: [
        "workspace", "workspacev2", "focusedmon", "focusedmonv2"
    ]
    readonly property list<string> workspaceEvents: [
        "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2",
        "moveworkspace", "moveworkspacev2", "renameworkspace", "activespecial", "activespecialv2"
    ]
    readonly property list<string> monitorEvents: [
        "monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2"
    ]
    readonly property list<string> ignoredEvents: [
        "activelayout", "submap", "screencast", "screencastv2",
        "ignoregrouplock", "lockgroups", "bell"
    ]

    function flushUpdates() {
        if (clientsDirty && !getClients.running) {
            clientsDirty = false;
            getClients.running = true;
        }
        if (monitorsDirty && !getMonitors.running) {
            monitorsDirty = false;
            getMonitors.running = true;
        }
        if (layersDirty && !getLayers.running) {
            layersDirty = false;
            getLayers.running = true;
        }
        if (workspacesDirty && !getWorkspaces.running) {
            workspacesDirty = false;
            getWorkspaces.running = true;
        }
        if (activeWorkspaceDirty && !getActiveWorkspace.running) {
            activeWorkspaceDirty = false;
            getActiveWorkspace.running = true;
        }
    }

    function scheduleFlush() {
        if ((clientsDirty || monitorsDirty || layersDirty || workspacesDirty || activeWorkspaceDirty)
                && !updateTimer.running) updateTimer.start();
    }

    function queueUpdates(updates) {
        clientsDirty = clientsDirty || !!updates.clients;
        monitorsDirty = monitorsDirty || !!updates.monitors;
        layersDirty = layersDirty || !!updates.layers;
        workspacesDirty = workspacesDirty || !!updates.workspaces;
        activeWorkspaceDirty = activeWorkspaceDirty || !!updates.activeWorkspace;
        scheduleFlush();
    }

    function updateWindowList() {
        clientsDirty = true;
        flushUpdates();
    }

    function updateLayers() {
        layersDirty = true;
        flushUpdates();
    }

    function updateMonitors() {
        monitorsDirty = true;
        flushUpdates();
    }

    function updateWorkspaces() {
        workspacesDirty = true;
        activeWorkspaceDirty = true;
        flushUpdates();
    }

    function updateAll() {
        clientsDirty = true;
        monitorsDirty = true;
        layersDirty = true;
        workspacesDirty = true;
        activeWorkspaceDirty = true;
        flushUpdates();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
    }

    Timer {
        id: updateTimer
        interval: 50
        onTriggered: root.flushUpdates()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = event.name;

            if (root.clientWorkspaceEvents.includes(name)) {
                root.queueUpdates({ clients: true, workspaces: true });
            } else if (root.clientEvents.includes(name)) {
                root.queueUpdates({ clients: true });
            } else if (root.activeWorkspaceEvents.includes(name)) {
                root.queueUpdates({ monitors: true, activeWorkspace: true });
            } else if (root.workspaceEvents.includes(name)) {
                root.queueUpdates({ monitors: true, workspaces: true, activeWorkspace: true });
            } else if (root.monitorEvents.includes(name) || name === "configreloaded") {
                root.queueUpdates({ clients: true, monitors: true, layers: true, workspaces: true, activeWorkspace: true });
            } else if (name === "openlayer" || name === "closelayer") {
                root.queueUpdates({ layers: true });
            } else if (!root.ignoredEvents.includes(name)) {
                // Preserve correctness for new Hyprland events until they are classified.
                root.queueUpdates({ clients: true, monitors: true, layers: true, workspaces: true, activeWorkspace: true });
            }
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        onRunningChanged: {
            if (!running) root.scheduleFlush();
        }
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text)
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        onRunningChanged: {
            if (!running) root.scheduleFlush();
        }
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        onRunningChanged: {
            if (!running) root.scheduleFlush();
        }
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                root.layers = JSON.parse(layersCollector.text);
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        onRunningChanged: {
            if (!running) root.scheduleFlush();
        }
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                var rawWorkspaces = JSON.parse(workspacesCollector.text);
                // Filter out invalid workspace ids (e.g. lock-screen temp workspace 2147483647 - N)
                root.workspaces = rawWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        onRunningChanged: {
            if (!running) root.scheduleFlush();
        }
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
            }
        }
    }
}
