import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight
import qs.modules.ii.sidebarRight.calendar
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()
    signal dismissRequested()

    function getUpcomingTodos() {
        const unfinishedTodos = Todo.list.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return Translation.tr("No pending tasks");
        }

        // Limit to first 5 todos to keep popup manageable
        const limitedTodos = unfinishedTodos.slice(0, 5);
        let todoText = limitedTodos.map(function (item, index) {
            return `  ${index + 1}. ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 5) {
            todoText += `\n  ${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 5)}`;
        }

        return todoText;
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 8

        StyledPopupHeaderRow {
            icon: "calendar_month"
            label: root.formattedDate
        }

        BottomWidgetGroup {
            collapsed: false
            selectedTab: 0
            implicitWidth: 420
            implicitHeight: 350
        }

        StyledPopupValueRow {
            icon: "timelapse"
            label: Translation.tr("System uptime:")
            value: root.formattedUptime
        }
    }
}
