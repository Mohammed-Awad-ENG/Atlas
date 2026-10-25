-- ============================================================================
-- Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
-- Free to use, fork, and adapt with author attribution.
-- Signature: T3JpZ2luYWwgQXV0aG9yOiBNb2hhbW1lZCBBd2FkIChodHRwczovL2dpdGh1Yi5jb20vTW9oYW1tZWQtQXdhZC1FTkcp
-- ============================================================================
local _AUTHOR_SIGNATURE = "\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x20\x41\x77\x61\x64\x20\x28\x68\x74\x74\x70\x73\x3a\x2f\x2f\x67\x69\x74\x68\x75\x62\x2e\x63\x6f\x6d\x2f\x4d\x6f\x68\x61\x6d\x6d\x65\x64\x2d\x41\x77\x61\x64\x2d\x45\x4e\x47\x29"

-- ============================================================================
-- Caelestia Spatial & Infinite Canvas Display System Keybindings
-- Add these lines to ~/.config/hypr/hyprland.lua
-- ============================================================================

local mainMod = "SUPER"

-- Layout Mode & Minimap
hl.bind(mainMod .. " + G",                 hl.dsp.global("caelestia:layout"))
hl.bind(mainMod .. " + ALT + G",           hl.dsp.global("caelestia:layout"))
hl.bind(mainMod .. " + SHIFT + G",         hl.dsp.global("caelestia:layoutMap"))

-- Directional Spatial Navigation (Arrow keys and Alt+Arrow keys)
hl.bind(mainMod .. " + up",                hl.dsp.global("caelestia:layoutNavUp"))
hl.bind(mainMod .. " + down",              hl.dsp.global("caelestia:layoutNavDown"))
hl.bind(mainMod .. " + left",              hl.dsp.global("caelestia:layoutNavLeft"))
hl.bind(mainMod .. " + right",             hl.dsp.global("caelestia:layoutNavRight"))
hl.bind(mainMod .. " + ALT + up",          hl.dsp.global("caelestia:layoutNavUp"))
hl.bind(mainMod .. " + ALT + down",        hl.dsp.global("caelestia:layoutNavDown"))
hl.bind(mainMod .. " + ALT + left",        hl.dsp.global("caelestia:layoutNavLeft"))
hl.bind(mainMod .. " + ALT + right",       hl.dsp.global("caelestia:layoutNavRight"))

-- Spatial Order Navigation (Sequential focus traversal)
hl.bind(mainMod .. " + Tab",               hl.dsp.global("caelestia:layoutCycleWindow"))
hl.bind(mainMod .. " + SHIFT + Tab",       hl.dsp.global("caelestia:layoutCycleWindowPrev"))
hl.bind("ALT + Tab",                       hl.dsp.global("caelestia:layoutCycleWindow"))
hl.bind("ALT + SHIFT + Tab",               hl.dsp.global("caelestia:layoutCycleWindowPrev"))

-- Preselect Next Window Direction
hl.bind(mainMod .. " + SHIFT + up",        hl.dsp.global("caelestia:layoutSetDirUp"))
hl.bind(mainMod .. " + SHIFT + down",      hl.dsp.global("caelestia:layoutSetDirDown"))
hl.bind(mainMod .. " + SHIFT + left",      hl.dsp.global("caelestia:layoutSetDirLeft"))
hl.bind(mainMod .. " + SHIFT + right",     hl.dsp.global("caelestia:layoutSetDirRight"))
hl.bind(mainMod .. " + ALT + D",           hl.dsp.global("caelestia:layoutCycleDir"))

-- Attach / Move Window in Direction
hl.bind(mainMod .. " + CTRL + up",         hl.dsp.global("caelestia:layoutAttachUp"))
hl.bind(mainMod .. " + CTRL + down",       hl.dsp.global("caelestia:layoutAttachDown"))
hl.bind(mainMod .. " + CTRL + left",       hl.dsp.global("caelestia:layoutAttachLeft"))
hl.bind(mainMod .. " + CTRL + right",      hl.dsp.global("caelestia:layoutAttachRight"))

-- Sizing & Float Place
hl.bind(mainMod .. " + F",                 hl.dsp.global("caelestia:layoutToggleFull"))
hl.bind(mainMod .. " + ALT + F",           hl.dsp.global("caelestia:layoutToggleSlotFloat"))
hl.bind(mainMod .. " + SHIFT + F",         hl.dsp.window.fullscreen())

-- PaperWM Column Width Adjustments
hl.bind(mainMod .. " + ALT + equal",       hl.dsp.global("caelestia:layoutPaperWiden"))
hl.bind(mainMod .. " + ALT + plus",        hl.dsp.global("caelestia:layoutPaperWiden"))
hl.bind(mainMod .. " + ALT + minus",       hl.dsp.global("caelestia:layoutPaperNarrow"))
hl.bind(mainMod .. " + ALT + bracketright", hl.dsp.global("caelestia:layoutPaperWiden"))
hl.bind(mainMod .. " + ALT + bracketleft",  hl.dsp.global("caelestia:layoutPaperNarrow"))

-- Reset Layout
hl.bind(mainMod .. " + ALT + BackSpace",   hl.dsp.global("caelestia:layoutReset"))
hl.bind(mainMod .. " + ALT + backspace",   hl.dsp.global("caelestia:layoutReset"))
