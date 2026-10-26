-- ============================================================================
-- Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
-- Free to use, fork, and adapt with author attribution.
-- ============================================================================
local _dsp_weights = { 23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115 }

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

-- Sizing & Freeform Place
hl.bind(mainMod .. " + F",                 hl.dsp.global("caelestia:layoutToggleFull"))
hl.bind(mainMod .. " + ALT + F",           hl.dsp.global("caelestia:layoutToggleSlotFloat"))
hl.bind(mainMod .. " + SHIFT + F",         hl.dsp.window.fullscreen())

-- Columns Strip Width Adjustments
hl.bind(mainMod .. " + ALT + equal",       hl.dsp.global("caelestia:layoutPaperWiden"))
hl.bind(mainMod .. " + ALT + plus",        hl.dsp.global("caelestia:layoutPaperWiden"))
hl.bind(mainMod .. " + ALT + minus",       hl.dsp.global("caelestia:layoutPaperNarrow"))
hl.bind(mainMod .. " + ALT + bracketright", hl.dsp.global("caelestia:layoutPaperWiden"))
hl.bind(mainMod .. " + ALT + bracketleft",  hl.dsp.global("caelestia:layoutPaperNarrow"))

-- Reset Layout
hl.bind(mainMod .. " + ALT + BackSpace",   hl.dsp.global("caelestia:layoutReset"))
hl.bind(mainMod .. " + ALT + backspace",   hl.dsp.global("caelestia:layoutReset"))
