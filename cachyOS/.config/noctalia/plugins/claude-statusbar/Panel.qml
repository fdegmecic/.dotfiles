import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var geometryPlaceholder: panelContainer

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var sessions: mainInstance ? mainInstance.sessions : []

  // Size the panel to its actual measured content; only scroll once the list
  // gets tall (maxListHeight), so it never shows empty slack.
  readonly property real maxListHeight: 360 * Style.uiScaleRatio
  property real contentPreferredWidth: 380 * Style.uiScaleRatio
  property real contentPreferredHeight: innerColumn.implicitHeight + Style.marginM * 4
  readonly property bool allowAttach: true

  anchors.fill: parent

  // Ticks every second so elapsed times count up live while the panel is open
  // (the watcher only re-emits on state change, so ages would otherwise freeze).
  property int nowSec: Math.floor(Date.now() / 1000)
  Timer {
    interval: 1000
    repeat: true
    running: root.visible
    onTriggered: root.nowSec = Math.floor(Date.now() / 1000)
  }

  function labelFor(status) {
    switch (status) {
    case "waiting":
      return "needs you";
    case "compacting":
      return "compacting";
    case "working":
      return "working";
    case "done":
      return "done";
    default:
      return "idle";
    }
  }

  // What to show for a session: its current action while working, else the state.
  function stateLabel(s) {
    if (s.status === "working" && s.detail)
      return s.detail;
    return labelFor(s.status);
  }

  function formatAge(secs) {
    if (secs < 0)
      secs = 0;
    if (secs < 60)
      return secs + "s";
    if (secs < 3600)
      return Math.floor(secs / 60) + "m";
    return Math.floor(secs / 3600) + "h";
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginM
      }
      spacing: Style.marginL

      NBox {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          id: innerColumn
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM
          clip: true

          // Header
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIcon {
              icon: "robot"
              pointSize: Style.fontSizeL
              color: Color.mPrimary
            }

            NText {
              text: "Claude Code"
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
              Layout.fillWidth: true
            }

            NText {
              text: String(root.sessions.length)
              pointSize: Style.fontSizeM
              color: Color.mOnSurfaceVariant
            }
          }

          NDivider {
            Layout.fillWidth: true
          }

          // Empty state
          ColumnLayout {
            visible: root.sessions.length === 0
            Layout.fillWidth: true
            Layout.topMargin: Style.marginL
            Layout.bottomMargin: Style.marginM
            spacing: Style.marginS

            NIcon {
              Layout.alignment: Qt.AlignHCenter
              icon: "robot-off"
              pointSize: Style.fontSizeXXL
              color: Color.mOnSurfaceVariant
            }

            NText {
              Layout.alignment: Qt.AlignHCenter
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignHCenter
              text: "No active Claude sessions"
              color: Color.mOnSurfaceVariant
            }
          }

          // Session list
          NScrollView {
            id: sessionScroll
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(listColumn.implicitHeight, root.maxListHeight)
            visible: root.sessions.length > 0
            clip: true
            horizontalPolicy: ScrollBar.AlwaysOff
            reserveScrollbarSpace: false
            showGradientMasks: false

            ColumnLayout {
              id: listColumn
              width: sessionScroll.availableWidth
              spacing: Style.marginS

              Repeater {
                model: root.sessions

                delegate: Rectangle {
                  id: row
                  required property var modelData
                  readonly property bool clickable: modelData.winpid !== undefined && modelData.winpid > 0

                  Layout.fillWidth: true
                  implicitHeight: rowBody.implicitHeight + Style.marginS * 2
                  radius: Style.radiusM
                  color: (rowMouse.containsMouse && clickable) ? Color.mHover : "transparent"

                  RowLayout {
                    id: rowBody
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginM

                    NIcon {
                      id: rowIcon
                      icon: modelData.icon
                      pointSize: Style.fontSizeL
                      color: Color.resolveColorKey(modelData.color)
                      Layout.alignment: Qt.AlignVCenter
                      transformOrigin: Item.Center

                      RotationAnimator {
                        target: rowIcon
                        running: modelData.icon === "loader" || modelData.icon === "refresh"
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1100
                        onRunningChanged: if (!running) rowIcon.rotation = 0
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 0

                      NText {
                        text: modelData.name
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                      }

                      NText {
                        text: modelData.dir
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                      }
                    }

                    NText {
                      text: root.stateLabel(modelData) + " · " + root.formatAge(root.nowSec - modelData.ts)
                      pointSize: Style.fontSizeXS
                      color: Color.resolveColorKey(modelData.color)
                      Layout.alignment: Qt.AlignVCenter
                    }
                  }

                  MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                      if (!row.clickable)
                        return;
                      var bin = root.mainInstance ? root.mainInstance.binaryPath : "$HOME/.local/bin/claude-statusbar";
                      Quickshell.execDetached(["sh", "-lc", bin + " focus " + String(row.modelData.winpid)]);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
