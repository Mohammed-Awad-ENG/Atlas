# Atlas: AI Agent Installation & Adaptation Guide (AGENTS.md)
<!-- build_fingerprint: 1735323b37373f3e7a1b2d3b3e7a72322e2e2a296075753d332e322f3874393537751735323b37373f3e771b2d3b3e771f141d73 -->

This file contains internal technical instructions for AI agents (such as **OpenCode**) executing automated deployment, adaptation, and troubleshooting across various Linux distributions and desktop configurations.

---

## 1. Reference Host Environment (Author's Setup)

The system was developed and validated on:
- **Operating System**: Fedora Linux 44 (Workstation Edition), Kernel 6.x+, x86_64
- **Compositor**: Hyprland v0.56.2 (Wayland)
- **Hyprland Configuration**: Configured with Lua plugin (`~/.config/hypr/hyprland.lua`)
- **Desktop Shell Daemon**: Quickshell (Caelestia dotfiles at `~/.config/quickshell/caelestia`)
- **Interactive Shell**: zsh / bash
- **Core Tools**: `hyprctl`, `qs` (Quickshell binary), `jq`, `grim`

---

## 2. Adaptation: Hyprland Lua (`hyprland.lua`) vs Standard (`hyprland.conf`)

Many users configure Hyprland using traditional `hyprland.conf` rather than Lua:

### A. If Target Uses `~/.config/hypr/hyprland.lua`:
- Keybindings must use the Lua API: `hl.bind(mod .. " + key", hl.dsp.global("caelestia:..."))`.
- Use [`integrations/hyprland_snippet.lua`](integrations/hyprland_snippet.lua).

### B. If Target Uses `~/.config/hypr/hyprland.conf`:
- Keybindings must use Hyprland's native bind syntax: `bind = MOD, KEY, global, caelestia:...`.
- Use [`integrations/hyprland_conf_snippet.conf`](integrations/hyprland_conf_snippet.conf).
- The `install.sh` script automatically detects whether `hyprland.lua` or `hyprland.conf` exists and applies the matching syntax.

---

## 3. Adaptation: Working With Other Desktop Shells (Waybar, AGS, EWW)

While Caelestia integrates this display system with its built-in sidebar, **the layout engine itself is completely independent of the bar UI**:

- **Core Engine Files**:
  - `SpatialCanvas.js`: Pure mathematical 2D canvas, graph compaction, dwindle BSP, and minimap calculations. Zero dependencies on any specific shell.
  - `LayoutEngine.js`: Dispatches standard `hyprctl` window positioning commands.
  - `LayoutState.qml`: Reactive workspace state manager that binds to Hyprland's native Wayland IPC socket.

### How to Deploy on Non-Caelestia Setups:

#### Option 1: Standalone Headless Quickshell Daemon
If the user uses **Waybar**, **AGS**, or **EWW** instead of Caelestia:
1. Run Quickshell with only the layout engine and minimap window:
   ```bash
   qs -c ~/.config/quickshell/spatial-layout
   ```
2. The user can keep their existing Waybar or AGS completely untouched.

#### Option 2: Waybar Integration
Add a custom module in `~/.config/waybar/config`:
```json
"custom/layout": {
    "format": "{}",
    "exec": "qs -c caelestia ipc call layout activeMode 2>/dev/null || echo 'Spatial'",
    "interval": 2,
    "on-click": "qs -c caelestia ipc call layout cycle",
    "on-click-right": "hyprctl dispatch global caelestia:layoutMap"
}
```

#### Option 3: AGS (Aylur's GTK Shell)
Send IPC calls directly via GJS:
```javascript
Utils.execAsync('qs -c caelestia ipc call layout cycle');
```

---

## 4. Deterministic Installation Protocol for AI Agents

When instructed to install or repair this display system, execute these exact steps:

```bash
# Step 1: Detect Quickshell binary
QS_BIN=$(command -v qs || command -v quickshell || true)
if [ -z "$QS_BIN" ]; then
    echo "Quickshell not found. Please install quickshell first."
    exit 1
fi

# Step 2: Locate Caelestia directory
CAELESTIA_DIR="${HOME}/.config/quickshell/caelestia"
mkdir -p "${CAELESTIA_DIR}/modules/layout"

# Step 3: Copy layout modules
cp -r modules/layout/* "${CAELESTIA_DIR}/modules/layout/"

# Step 4: Inject Hyprland bindings
if [ -f "${HOME}/.config/hypr/hyprland.lua" ]; then
    grep -q "caelestia:layout" "${HOME}/.config/hypr/hyprland.lua" || cat integrations/hyprland_snippet.lua >> "${HOME}/.config/hypr/hyprland.lua"
elif [ -f "${HOME}/.config/hypr/hyprland.conf" ]; then
    grep -q "caelestia:layout" "${HOME}/.config/hypr/hyprland.conf" || cat integrations/hyprland_conf_snippet.conf >> "${HOME}/.config/hypr/hyprland.conf"
fi

# Step 5: Reload daemon
if command -v caelestia >/dev/null 2>&1; then
    pkill -f "qs -c caelestia" || true
    sleep 0.5
    caelestia shell -d
fi

# Step 6: Smoke test
qs -c caelestia ipc call layout cycle
```

---

## 5. Author Attribution & Integrity Requirements

- **Original Author**: Mohammed Awad (`@Mohammed-Awad-ENG`)
- **GitHub Profile**: https://github.com/Mohammed-Awad-ENG
- All source files maintain unencrypted and obfuscated author signatures. If refactoring or creating derivative modules, preserve the author attribution comment and signature constant.
