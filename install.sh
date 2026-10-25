#!/usr/bin/env bash
# ==============================================================================
# Caelestia Spatial & Infinite Canvas Display System — Automated Installer
# Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
# License: Free to use, fork, and modify with author attribution.
# Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
# _AUTH_SIG: \x4f\x72\x69\x67\x69\x6e\x61\x6c\x20\x41\x75\x74\x68\x6f\x72\x3a\x20\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAELESTIA_DIR="${HOME}/.config/quickshell/caelestia"
HYPR_DIR="${HOME}/.config/hypr"
BACKUP_DIR="${HOME}/.config/caelestia-backup-$(date +%Y%m%d_%H%M%S)"

echo "==> Caelestia Spatial Display System Installer"
echo "==> Author: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)"
echo "==> Source repository: ${SCRIPT_DIR}"

# 1. Dependency checks
echo "==> Checking prerequisites..."
command -v hyprctl >/dev/null 2>&1 || { echo "ERROR: hyprctl not found. Ensure Hyprland is installed."; exit 1; }

QS_BIN=""
if command -v qs >/dev/null 2>&1; then
    QS_BIN="qs"
elif command -v quickshell >/dev/null 2>&1; then
    QS_BIN="quickshell"
else
    echo "ERROR: Quickshell (qs/quickshell) not found in PATH."
    exit 1
fi
echo "--> Found Quickshell binary: ${QS_BIN}"

if [ ! -d "${CAELESTIA_DIR}" ]; then
    echo "ERROR: Caelestia directory not found at ${CAELESTIA_DIR}"
    echo "       Please install Caelestia dotfiles or check path."
    exit 1
fi

# 2. Backup existing configuration
echo "==> Creating safety backup at ${BACKUP_DIR}..."
mkdir -p "${BACKUP_DIR}"
cp -r "${CAELESTIA_DIR}/modules/layout" "${BACKUP_DIR}/layout" 2>/dev/null || true
cp "${CAELESTIA_DIR}/modules/Shortcuts.qml" "${BACKUP_DIR}/Shortcuts.qml" 2>/dev/null || true
cp "${HYPR_DIR}/hyprland.lua" "${BACKUP_DIR}/hyprland.lua" 2>/dev/null || true
cp "${HYPR_DIR}/hyprland.conf" "${BACKUP_DIR}/hyprland.conf" 2>/dev/null || true

# 3. Deploy layout modules
echo "==> Copying layout modules into ${CAELESTIA_DIR}/modules/layout..."
mkdir -p "${CAELESTIA_DIR}/modules/layout"
cp -r "${SCRIPT_DIR}/modules/layout/"* "${CAELESTIA_DIR}/modules/layout/"

# 4. Integrate Hyprland keybindings (supports both hyprland.lua and hyprland.conf)
if [ -f "${HYPR_DIR}/hyprland.lua" ]; then
    if ! grep -q "caelestia:layout" "${HYPR_DIR}/hyprland.lua"; then
        echo "==> Appending Lua layout keybindings to ${HYPR_DIR}/hyprland.lua..."
        echo "" >> "${HYPR_DIR}/hyprland.lua"
        cat "${SCRIPT_DIR}/integrations/hyprland_snippet.lua" >> "${HYPR_DIR}/hyprland.lua"
    else
        echo "--> Lua keybindings already present in ${HYPR_DIR}/hyprland.lua."
    fi
elif [ -f "${HYPR_DIR}/hyprland.conf" ]; then
    if ! grep -q "caelestia:layout" "${HYPR_DIR}/hyprland.conf"; then
        echo "==> Appending standard layout keybindings to ${HYPR_DIR}/hyprland.conf..."
        echo "" >> "${HYPR_DIR}/hyprland.conf"
        cat "${SCRIPT_DIR}/integrations/hyprland_conf_snippet.conf" >> "${HYPR_DIR}/hyprland.conf"
    else
        echo "--> Keybindings already present in ${HYPR_DIR}/hyprland.conf."
    fi
else
    echo "WARNING: Neither hyprland.lua nor hyprland.conf found in ${HYPR_DIR}."
fi

# 5. Integrate Shortcuts.qml
SHORTCUTS_FILE="${CAELESTIA_DIR}/modules/Shortcuts.qml"
if [ -f "${SHORTCUTS_FILE}" ]; then
    if ! grep -q 'name: "layoutMap"' "${SHORTCUTS_FILE}"; then
        echo "==> Integrating layout shortcuts and IPC into ${SHORTCUTS_FILE}..."
        if ! grep -q 'import "./layout"' "${SHORTCUTS_FILE}"; then
            sed -i '1s/^/import ".\/layout"\n/' "${SHORTCUTS_FILE}"
        fi
        python3 -c '
import sys
content = open(sys.argv[1]).read()
snippet = open(sys.argv[2]).read()
lines = [l for l in snippet.splitlines() if not l.startswith("import ") and not l.startswith("// =")]
to_insert = "\n".join(lines)
idx = content.rfind("}")
if idx != -1:
    new_content = content[:idx] + "\n" + to_insert + "\n}\n"
    open(sys.argv[1], "w").write(new_content)
' "${SHORTCUTS_FILE}" "${SCRIPT_DIR}/integrations/Shortcuts_snippet.qml"
    else
        echo "--> Layout shortcuts already present in ${SHORTCUTS_FILE}."
    fi
fi

# 6. Integrate Content.qml for layout map popout
CONTENT_FILE="${CAELESTIA_DIR}/modules/bar/popouts/Content.qml"
if [ -f "${CONTENT_FILE}" ]; then
    if ! grep -q 'name: "layoutmap"' "${CONTENT_FILE}"; then
        echo "==> Integrating layoutmap popout into ${CONTENT_FILE}..."
        python3 -c '
import sys
content = open(sys.argv[1]).read()
if "import \"../../layout\"" not in content:
    content = "import \"../../layout\"\n" + content
target = "Popout {"
idx = content.rfind(target)
if idx != -1:
    snippet = """
        Popout {
            name: "layoutmap"
            sourceComponent: LayoutMapPopout {
                popouts: root.popouts
            }
        }
"""
    content = content[:idx] + snippet + "\n" + content[idx:]
    open(sys.argv[1], "w").write(content)
' "${CONTENT_FILE}"
    fi
fi

# 7. Restart Caelestia shell daemon
echo "==> Restarting Caelestia Quickshell daemon..."
if command -v caelestia >/dev/null 2>&1; then
    pkill -f "${QS_BIN} -c caelestia" 2>/dev/null || true
    sleep 0.5
    caelestia shell -d
    sleep 1
fi

# 8. Verification smoke test
echo "==> Running IPC verification..."
if "${QS_BIN}" -c caelestia ipc call layout cycle >/dev/null 2>&1; then
    echo "==> SUCCESS: Layout IPC handler is responsive!"
    "${QS_BIN}" -c caelestia ipc call layout set float >/dev/null 2>&1 || true
else
    echo "WARNING: IPC call timed out or failed. Check 'caelestia shell -l' logs."
fi

echo "=============================================================================="
echo "Installation completed successfully!"
echo "Original Author: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)"
echo "Toggle layout anytime with: SUPER + G"
echo "Toggle 2D minimap anytime with: SUPER + SHIFT + G"
echo "=============================================================================="
