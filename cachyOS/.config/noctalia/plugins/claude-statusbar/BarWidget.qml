import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property bool pillDirection: BarService.getPillDirection(root)
  readonly property var mainInstance: pluginApi?.mainInstance

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property bool showCountWhenSingle: cfg.showCountWhenSingle ?? defaults.showCountWhenSingle ?? false
  readonly property bool hideWhenEmpty: cfg.hideWhenEmpty ?? defaults.hideWhenEmpty ?? false
  readonly property bool showLabel: cfg.showLabel ?? defaults.showLabel ?? true
  readonly property string labelText: mainInstance ? mainInstance.aggLabel : ""

  // A user-set color (not "none") overrides the dynamic state color.
  readonly property string iconColorKey: {
    var k = cfg.iconColor ?? defaults.iconColor ?? "none";
    if (k !== "none")
      return k;
    return mainInstance ? mainInstance.aggColorKey : "secondary";
  }
  readonly property color iconColor: Color.resolveColorKey(iconColorKey)

  readonly property string textColorKey: {
    var k = cfg.textColor ?? defaults.textColor ?? "none";
    if (k !== "none")
      return k;
    return mainInstance ? mainInstance.aggColorKey : "secondary";
  }
  readonly property color textColor: Color.resolveColorKey(textColorKey)

  readonly property string iconName: mainInstance ? mainInstance.aggIcon : "robot"
  readonly property bool spinning: iconName === "loader" || iconName === "refresh"
  readonly property bool alerting: iconName === "bell-ringing"
  readonly property int total: mainInstance ? mainInstance.total : 0
  readonly property string countText: {
    if (total <= 0)
      return "";
    if (total === 1 && !showCountWhenSingle)
      return "";
    return String(total);
  }

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  // Label baked the count in ("3 working"), so only show the bare number when the label is off.
  readonly property bool showLbl: !isVertical && showLabel && labelText !== ""
  readonly property bool showCount: !isVertical && !showLbl && countText !== ""
  readonly property bool hasText: showCount || showLbl
  readonly property real contentWidth: {
    if (isVertical)
      return capsuleHeight;
    if (hasText)
      return contentRow.implicitWidth + Style.marginM * 2;
    return capsuleHeight;
  }

  implicitWidth: contentWidth
  implicitHeight: capsuleHeight
  visible: !(hideWhenEmpty && total === 0)

  // Little pop whenever the session count changes (one appears / finishes).
  onTotalChanged: popAnim.restart()
  SequentialAnimation {
    id: popAnim
    NumberAnimation {
      target: visualCapsule
      property: "scale"
      from: 1.0
      to: 1.14
      duration: 110
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: visualCapsule
      property: "scale"
      from: 1.14
      to: 1.0
      duration: 180
      easing.type: Easing.OutBack
    }
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.capsuleHeight
    transformOrigin: Item.Center
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.marginS
      layoutDirection: pillDirection ? Qt.LeftToRight : Qt.RightToLeft

      NIcon {
        id: stateIcon
        icon: root.iconName
        applyUiScale: false
        color: mouseArea.containsMouse ? Color.mOnHover : root.iconColor
        transformOrigin: Item.Center

        // Ease state-colour changes (blue -> green -> red) instead of snapping.
        Behavior on color {
          ColorAnimation {
            duration: 220
          }
        }

        // Spin continuously while any session is working / compacting.
        RotationAnimator {
          target: stateIcon
          running: root.spinning
          loops: Animation.Infinite
          from: 0
          to: 360
          duration: 1100
          onRunningChanged: if (!running) stateIcon.rotation = 0
        }

        // Pulse for attention while a session needs you (permission prompt).
        SequentialAnimation {
          running: root.alerting
          loops: Animation.Infinite
          onRunningChanged: if (!running) stateIcon.opacity = 1.0
          NumberAnimation {
            target: stateIcon
            property: "opacity"
            from: 1.0
            to: 0.35
            duration: 600
            easing.type: Easing.InOutQuad
          }
          NumberAnimation {
            target: stateIcon
            property: "opacity"
            from: 0.35
            to: 1.0
            duration: 600
            easing.type: Easing.InOutQuad
          }
        }
      }

      NText {
        visible: root.showLbl
        pointSize: root.barFontSize
        font.weight: Style.fontWeightBold
        color: mouseArea.containsMouse ? Color.mOnHover : root.textColor
        text: root.labelText
      }

      NText {
        visible: root.showCount
        family: Settings.data.ui.fontFixed
        pointSize: root.barFontSize
        font.weight: Style.fontWeightBold
        color: mouseArea.containsMouse ? Color.mOnHover : root.textColor
        text: root.countText
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      {
        "label": "Settings",
        "action": "widget-settings",
        "icon": "settings"
      }
    ]
    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "widget-settings")
        BarService.openPluginSettings(screen, pluginApi.manifest);
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      TooltipService.hide();
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi)
          pluginApi.togglePanel(root.screen, root);
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }

    onEntered: {
      if (mainInstance && mainInstance.aggTooltip)
        TooltipService.show(root, mainInstance.aggTooltip, BarService.getTooltipDirection(screenName));
    }
    onExited: TooltipService.hide()
  }
}
