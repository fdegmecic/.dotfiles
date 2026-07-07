import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.Noctalia

Item {
  id: root

  property var pluginApi: null

  // Pre-compile Panel.qml at startup so the first open is warm (the shell
  // compiles it lazily on first click otherwise -> visible first-open lag).
  // Must match the exact URL the panel slot uses, including the ?v= version.
  property var _panelWarmup: null
  Component.onCompleted: {
    if (!pluginApi || !pluginApi.pluginDir)
      return;
    var v = 0;
    try {
      v = PluginRegistry.pluginLoadVersions[pluginApi.pluginId] || 0;
    } catch (e) {}
    root._panelWarmup = Qt.createComponent("file://" + pluginApi.pluginDir + "/Panel.qml?v=" + v, Component.Asynchronous);
  }

  // Aggregate state, consumed by BarWidget and Panel
  property string aggText: ""
  property string aggLabel: ""
  property string aggIcon: "robot"
  property string aggColorKey: "secondary"
  property string aggTooltip: ""
  property int total: 0
  property var sessions: []

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string binaryPath: cfg.binaryPath ?? defaults.binaryPath ?? "$HOME/.local/bin/claude-statusbar"

  IpcHandler {
    target: "plugin:claude-statusbar"

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.togglePanel(screen);
        });
      }
    }
  }

  function ingest(line) {
    if (!line || line.trim() === "")
      return;
    try {
      var d = JSON.parse(line);
      root.aggText = d.text || "";
      root.aggLabel = d.label || "";
      root.aggIcon = d.icon || "robot";
      root.aggColorKey = d.color || "secondary";
      root.aggTooltip = d.tooltip || "";
      root.sessions = d.sessions || [];
      root.total = root.sessions.length;
    } catch (e) {
      Logger.w("ClaudeStatus", "Failed to parse line: " + line);
    }
  }

  // Long-lived `claude-statusbar watch` process: pushes a fresh JSON line the
  // instant any session changes state (no polling).
  Process {
    id: proc
    command: ["sh", "-lc", "exec \"" + root.binaryPath + "\" watch"]
    running: true
    stdout: SplitParser {
      onRead: line => root.ingest(line)
    }
    onExited: (code, status) => restartTimer.start()
  }

  // Respawn the watcher if it ever dies.
  Timer {
    id: restartTimer
    interval: 1000
    repeat: false
    onTriggered: {
      if (!proc.running)
        proc.running = true;
    }
  }
}
