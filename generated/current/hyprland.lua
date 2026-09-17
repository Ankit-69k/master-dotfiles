-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- AUTO-GENERATED — theme: tokyo-night
-- Hyprland 0.55+ Lua config.
-- Edit config/hypr/hyprland.lua.template, not this file.
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local background = "rgb(1a1b26)"
local accent = "rgb(7aa2f7)"
local inactive = "rgb(565f89)"
local activeBorder   = "rgba(7aa2f7ee)"
local inactiveBorder = "rgba(565f89aa)"
local shadowColor     = "rgba(1a1b26ee)"


-- --- Autostart ---
hl.on("hyprland.start", function()
	hl.exec_cmd("~/my-rice/scripts/startup")
end)

-- --- Monitor ---
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60.00800",
    position = "auto",
    scale = 1.33,
})

-- --- Look & feel (pulled from theme.conf) ---
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
    border_size = 2,	
    col = {
      active_border = activeBorder,
      inactive_border = inactiveBorder,
    },
		layout = "dwindle",
	},
	decoration = {
		rounding = 10,
		blur = { enabled = true, size = 6, passes = 2 },
		shadow = { enabled = true, range = 12, color = background },
	},
	misc = {
		font_family = "JetBrainsMono Nerd Font",
    disable_splash_rendering = true,
    disable_hyprland_logo = true

	},
})

hl.window_rule({
    name = "wifi-menu",
    match = {
        title = "^WiFi Menu$",
    },
    float = true,
    size = { 700, 500 },
    center = true,
})

hl.window_rule({
    name = "bluetooth-menu",
    match = {
        title = "^Bluetooth Menu$",
    },
    float = true,
    size = { 700, 500 },
    center = true,
})

hl.window_rule({
    name = "sound-menu",
    match = {
        title = "^Sound Menu$",
    },
    float = true,
    size = { 700, 500 },
    center = true,
})

hl.window_rule({
    name = "system-monitor",
    match = {
        title = "^System Monitor$",
    },
    float = true,
    size = { 900, 600 },
    center = true,
})

hl.window_rule({
    name = "mpv-floating",
    match = {
        class = "^mpv$",
    },
    float = true,
    center = true,
})

hl.curve("riceCurve", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "riceCurve" })
hl.animation({ leaf = "border",     enabled = true, speed = 8, bezier = "riceCurve" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "riceCurve" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "riceCurve" })

-- --- Keybinds (static, unthemed — see config/hypr/keybinds.lua) ---
require("keybinds")
