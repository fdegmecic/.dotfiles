#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Kill Mouseless
# @vicinae.mode silent
# @vicinae.icon ../../icons/hicolor/512x512/apps/mouseless.png
# @vicinae.keywords ["mouseless", "kill", "stop", "quit"]

pkill -x mouseless 2>/dev/null
pkill -f 'Mouseless_v.*\.AppImage' 2>/dev/null
exit 0
