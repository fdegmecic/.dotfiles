import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null

  property bool editShowLabel: pluginApi?.pluginSettings?.showLabel ?? pluginApi?.manifest?.metadata?.defaultSettings?.showLabel ?? true
  property string editIconColor: pluginApi?.pluginSettings?.iconColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.iconColor ?? "none"
  property string editTextColor: pluginApi?.pluginSettings?.textColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.textColor ?? "none"
  property bool editShowCountWhenSingle: pluginApi?.pluginSettings?.showCountWhenSingle ?? pluginApi?.manifest?.metadata?.defaultSettings?.showCountWhenSingle ?? false
  property bool editHideWhenEmpty: pluginApi?.pluginSettings?.hideWhenEmpty ?? pluginApi?.manifest?.metadata?.defaultSettings?.hideWhenEmpty ?? false
  property string editBinaryPath: pluginApi?.pluginSettings?.binaryPath ?? pluginApi?.manifest?.metadata?.defaultSettings?.binaryPath ?? "$HOME/.local/bin/claude-statusbar"

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("ClaudeStatus", "Cannot save: pluginApi is null");
      return;
    }
    pluginApi.pluginSettings.showLabel = root.editShowLabel;
    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.pluginSettings.textColor = root.editTextColor;
    pluginApi.pluginSettings.showCountWhenSingle = root.editShowCountWhenSingle;
    pluginApi.pluginSettings.hideWhenEmpty = root.editHideWhenEmpty;
    pluginApi.pluginSettings.binaryPath = root.editBinaryPath;
    pluginApi.saveSettings();
    Logger.i("ClaudeStatus", "Settings saved");
  }

  NToggle {
    label: "Show status label"
    description: "Show a short status in the bar (\"3 working\", \"1 needs you\"). Off shows just the count."
    checked: root.editShowLabel
    onToggled: checked => root.editShowLabel = checked
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showLabel ?? true
  }

  NColorChoice {
    label: "Icon color override"
    description: "Leave at default to color by session state (red = needs you, blue = working, green = done)."
    currentKey: root.editIconColor
    onSelected: key => root.editIconColor = key
  }

  NColorChoice {
    label: "Count color override"
    currentKey: root.editTextColor
    onSelected: key => root.editTextColor = key
  }

  NToggle {
    label: "Show count for a single session"
    description: "Display the number even when only one session is running."
    checked: root.editShowCountWhenSingle
    onToggled: checked => root.editShowCountWhenSingle = checked
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showCountWhenSingle ?? false
  }

  NToggle {
    label: "Hide when no sessions"
    description: "Remove the widget from the bar entirely when no Claude sessions are running."
    checked: root.editHideWhenEmpty
    onToggled: checked => root.editHideWhenEmpty = checked
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hideWhenEmpty ?? false
  }
}
