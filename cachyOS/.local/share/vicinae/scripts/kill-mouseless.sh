#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Kill Mouseless
# @vicinae.mode silent
# @vicinae.icon ../../icons/hicolor/512x512/apps/mouseless.png
# @vicinae.keywords ["mouseless", "kill", "stop", "quit"]

flatpak kill net.sonuscape.mouseless 2>/dev/null
exit 0
