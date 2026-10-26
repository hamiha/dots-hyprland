import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Provides a list of wallpapers and an "apply" action that calls the existing
 * switchwall.sh script. Pretty much a limited file browsing service.
 */
Singleton {
    id: root

    property string thumbgenScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/thumbgen-venv.sh`
    property string generateThumbnailsMagickScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/generate-thumbnails-magick.sh`
    property alias directory: folderModel.folder
    readonly property string effectiveDirectory: FileUtils.trimFileProtocol(folderModel.folder.toString())
    property url defaultFolder: Qt.resolvedUrl(`${Directories.pictures}/Wallpapers`)
    property alias folderModel: folderModel // Expose for direct binding when needed
    property string searchQuery: ""
    readonly property list<string> extensions: [ // TODO: add videos
        "jpg", "jpeg", "png", "webp", "avif", "bmp", "svg"
    ]
    property list<string> wallpapers: [] // List of absolute file paths (without file://)
    readonly property bool thumbnailGenerationRunning: thumbgenProc.running
    property real thumbnailGenerationProgress: 0

    signal changed()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load () {} // For forcing initialization
    
    function focusedMonitorName() {
        const name = Hyprland.focusedMonitor?.name;
        return typeof name === "string" && Quickshell.screens.some(screen => screen.name === name) ? name : "";
    }

    function pathForMonitor(monitorName) {
        const paths = Config.options.background.wallpaperPaths;
        const path = paths && typeof paths === "object" && !Array.isArray(paths)
            && Object.prototype.hasOwnProperty.call(paths, monitorName) ? paths[monitorName] : null;
        return typeof path === "string" && path.trim().length > 0 ? path : Config.options.background.wallpaperPath;
    }

    function startApply(args, monitorName) {
        if (!monitorName || !Quickshell.screens.some(screen => screen.name === monitorName)) {
            console.error("Wallpaper: no valid target monitor");
            return;
        }
        if (applyProc.running) return;
        applyProc.exec([Directories.wallpaperSwitchScriptPath, "--monitor", monitorName, ...args]);
    }

    function openFallbackPicker(darkMode = Appearance.m3colors.darkmode, monitorName = root.focusedMonitorName()) {
        root.startApply(["--mode", darkMode ? "dark" : "light"], monitorName);
    }

    function apply(path, darkMode = Appearance.m3colors.darkmode, monitorName = root.focusedMonitorName()) {
        if (!path || path.length === 0) return;
        root.startApply(["--mode", darkMode ? "dark" : "light", "--image", FileUtils.trimFileProtocol(path)], monitorName);
    }

    Process {
        id: applyProc
        stderr: StdioCollector {
            id: applyErrors
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && exitStatus === 0) root.changed();
            else {
                const message = applyErrors.text.trim() || "Wallpaper apply failed";
                console.error(message);
                Quickshell.execDetached(["notify-send", "Wallpaper", message]);
            }
        }
    }

    Process {
        id: selectProc
        property string filePath: ""
        property bool darkMode: Appearance.m3colors.darkmode
        property string monitorName: ""
        function select(filePath, darkMode, monitorName) {
            // Keep in-flight directory checks pinned to their original request.
            if (selectProc.running) return;
            selectProc.filePath = filePath;
            selectProc.darkMode = darkMode;
            selectProc.monitorName = monitorName;
            selectProc.exec(["test", "-d", FileUtils.trimFileProtocol(filePath)]);
        }
        onExited: (exitCode, exitStatus) => {
            if (exitStatus !== 0) return;
            if (exitCode === 0) {
                root.setDirectory(selectProc.filePath);
                return;
            }
            root.apply(selectProc.filePath, selectProc.darkMode, selectProc.monitorName);
        }
    }

    function select(filePath, darkMode = Appearance.m3colors.darkmode, monitorName = root.focusedMonitorName()) {
        selectProc.select(filePath, darkMode, monitorName);
    }

    function randomFromCurrentFolder(darkMode = Appearance.m3colors.darkmode, monitorName = root.focusedMonitorName()) {
        if (folderModel.count === 0) return;
        const randomIndex = Math.floor(Math.random() * folderModel.count);
        const filePath = folderModel.get(randomIndex, "filePath");
        root.select(filePath, darkMode, monitorName);
    }

    Process {
        id: validateDirProc
        property string nicePath: ""
        function setDirectoryIfValid(path) {
            validateDirProc.nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "")
            if (/^\/*$/.test(validateDirProc.nicePath)) validateDirProc.nicePath = "/";
            validateDirProc.exec([
                "bash", "-c",
                'if [ -d "$1" ]; then echo dir; elif [ -f "$1" ]; then echo file; else echo invalid; fi',
                "wallpaper-directory", validateDirProc.nicePath
            ])
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const result = text.trim()
                if (result === "dir") {
                    root.directory = Qt.resolvedUrl(validateDirProc.nicePath)
                } else if (result === "file") {
                    root.directory = Qt.resolvedUrl(FileUtils.parentDirectory(validateDirProc.nicePath))
                } else {
                    // Ignore
                }
            }
        }
    }
    function setDirectory(path) {
        validateDirProc.setDirectoryIfValid(path)
    }
    function navigateUp() {
        folderModel.navigateUp()
    }
    function navigateBack() {
        folderModel.navigateBack()
    }
    function navigateForward() {
        folderModel.navigateForward()
    }

    // Folder model
    FolderListModelWithHistory {
        id: folderModel
        folder: Qt.resolvedUrl(root.defaultFolder)
        caseSensitive: false
        nameFilters: root.extensions.map(ext => `*${searchQuery.split(" ").filter(s => s.length > 0).map(s => `*${s}*`)}*.${ext}`)
        showDirs: true
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false
        onCountChanged: {
            root.wallpapers = []
            for (let i = 0; i < folderModel.count; i++) {
                const path = folderModel.get(i, "filePath") || FileUtils.trimFileProtocol(folderModel.get(i, "fileURL"))
                if (path && path.length) root.wallpapers.push(path)
            }
        }
    }

    // Thumbnail generation
    function generateThumbnail(size: string) {
        if (!["normal", "large", "x-large", "xx-large"].includes(size)) throw new Error("Invalid thumbnail size");
        thumbgenProc.directory = root.directory
        thumbgenProc.running = false
        thumbgenProc.command = [
            "bash", "-c",
            `${thumbgenScriptPath} --size ${size} --machine_progress -d ${FileUtils.trimFileProtocol(root.directory)} || ${generateThumbnailsMagickScriptPath} --size ${size} -d ${FileUtils.trimFileProtocol(root.directory)}`,
        ]
        // console.log("[Wallpapers] Updating thumbnails with command ", thumbgenProc.command.join(" "))
        root.thumbnailGenerationProgress = 0
        thumbgenProc.running = true
    }
    Process {
        id: thumbgenProc
        property string directory
        stdout: SplitParser {
            onRead: data => {
                // print("thumb gen proc:", data)
                let match = data.match(/PROGRESS (\d+)\/(\d+)/)
                if (match) {
                    const completed = parseInt(match[1])
                    const total = parseInt(match[2])
                    root.thumbnailGenerationProgress = completed / total
                }
                match = data.match(/FILE (.+)/)
                if (match) {
                    const filePath = match[1]
                    root.thumbnailGeneratedFile(filePath)
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // print("[Wallpapers] Thumbnail generation completed with exit code", exitCode)
            root.thumbnailGenerated(thumbgenProc.directory)
        }
    }

    IpcHandler {
        target: "wallpapers"

        function apply(path: string): void {
            root.apply(path);
        }
    }
}
