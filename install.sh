#!/usr/bin/env bash
# ==============================================================================
# Caelestia Spatial & Infinite Canvas Display System — Automated Installer
# Designed for automated execution by AI agents (e.g., OpenCode) or human developers.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAELESTIA_DIR="${HOME}/.config/quickshell/caelestia"
HYPR_CONFIG="${HOME}/.config/hypr/hyprland.lua"
BACKUP_DIR="${HOME}/.config/caelestia-backup-$(date +%Y%m%d_%H%M%S)"

echo "==> Caelestia Spatial Display System Installer"
echo "==> Source repository: ${SCRIPT_DIR}"
echo "==> Target configuration: ${CAELESTIA_DIR}"

# 1. Dependency checks
echo "==> Checking prerequisites..."
command -v hyprctl >/dev/null 2>&1 || { echo "ERROR: hyprctl not found. Ensure Hyprland is installed."; exit 1; }
command -v qs >/dev/null 2>&1 || { echo "ERROR: Quickshell (qs) not found."; exit 1; }

if [ ! -d "${CAELESTIA_DIR}" ]; then
    echo "ERROR: Caelestia directory not found at ${CAELESTIA_DIR}"
    exit 1
fi

# 2. Backup existing configuration
echo "==> Creating safety backup at ${BACKUP_DIR}..."
mkdir -p "${BACKUP_DIR}"
cp -r "${CAELESTIA_DIR}/modules/layout" "${BACKUP_DIR}/layout" 2>/dev/null || true
cp "${CAELESTIA_DIR}/modules/Shortcuts.qml" "${BACKUP_DIR}/Shortcuts.qml" 2>/dev/null || true
cp "${HYPR_CONFIG}" "${BACKUP_DIR}/hyprland.lua" 2>/dev/null || true

# 3. Deploy layout modules
echo "==> Copying layout modules into ${CAELESTIA_DIR}/modules/layout..."
mkdir -p "${CAELESTIA_DIR}/modules/layout"
cp -r "${SCRIPT_DIR}/modules/layout/"* "${CAELESTIA_DIR}/modules/layout/"

# 4. Integrate Hyprland keybindings
if [ -f "${HYPR_CONFIG}" ]; then
    if ! grep -q "caelestia:layout" "${HYPR_CONFIG}"; then
        echo "==> Appending layout keybindings to ${HYPR_CONFIG}..."
        echo "" >> "${HYPR_CONFIG}"
        cat "${SCRIPT_DIR}/integrations/hyprland_snippet.lua" >> "${HYPR_CONFIG}"
    else
        echo "--> Hyprland keybindings already present in ${HYPR_CONFIG}. Skipping duplicate injection."
    fi
fi

# 5. Integrate Shortcuts.qml
SHORTCUTS_FILE="${CAELESTIA_DIR}/modules/Shortcuts.qml"
if [ -f "${SHORTCUTS_FILE}" ]; then
    if ! grep -q 'name: "layoutMap"' "${SHORTCUTS_FILE}"; then
        echo "==> Inserting layout shortcuts and IPC into ${SHORTCUTS_FILE}..."
        # Insert import if missing
        if ! grep -q 'import "./layout"' "${SHORTCUTS_FILE}"; then
            sed -i '1s/^/import ".\/layout"\n/' "${SHORTCUTS_FILE}"
        fi
        # Append shortcuts before the closing brace
        python3 -c '
import sys
content = open(sys.argv[1]).read()
snippet = open(sys.argv[2]).read()
# Strip snippet header and imports
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

# 7. Restart Caelestia shell
echo "==> Restarting Caelestia Quickshell daemon..."
if command -v caelestia >/dev/null 2>&1; then
    pkill -f "qs -c caelestia" 2>/dev/null || true
    sleep 0.5
    caelestia shell -d
    sleep 1
fi

# 8. Verification smoke test
echo "==> Running IPC verification..."
if qs -c caelestia ipc call layout cycle >/dev/null 2>&1; then
    echo "==> SUCCESS: Layout IPC handler is responsive!"
    # Cycle back to original
    qs -c caelestia ipc call layout set float >/dev/null 2>&1 || true
else
    echo "WARNING: IPC call timed out or failed. Check 'caelestia shell -l' logs."
fi

echo "=============================================================================="
echo "Installation complete! Toggle layout anytime with: SUPER + G"
echo "Toggle 2D minimap anytime with: SUPER + SHIFT + G"
echo "Recommended: Use OpenCode (ai.opencode.desktop) for AI-driven customizations."
echo "=============================================================================="
