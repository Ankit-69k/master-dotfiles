-- Static keybinds — not theme-dependent.
-- Copied as-is into generated/current/ on every `generate-theme` run
-- and required from hyprland.lua via require("keybinds").

local mainMod = "SUPER"
local secondMod = "SUPER+SHIFT"

hl.bind(mainMod .. "+RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. "+Q", hl.dsp.window.close())
hl.bind(mainMod .. "+SPACE", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. "+B", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. "+F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. "+T", hl.dsp.exec_cmd("~/my-rice/scripts/rice pick"))
hl.bind(mainMod .. "+V", hl.dsp.exec_cmd("~/my-rice/scripts/clipboard"))
hl.bind(secondMod .. "+R", function()
	hl.exec_cmd("pkill waybar")
	hl.exec_cmd("waybar")
	hl.dispatch(hl.dsp.no_op())
end)
hl.bind(secondMod .. "+F", hl.dsp.exec_cmd("nemo"))
hl.bind(secondMod .. "+W", hl.dsp.exec_cmd("chromium --app=https://web.whatsapp.com"))
hl.bind(secondMod .. "+T", hl.dsp.exec_cmd("~/my-rice/scripts/theme-menu"))
hl.bind(secondMod .. "+P", hl.dsp.exec_cmd("~/my-rice/scripts/wallpaper-menu"))
for i = 1, 9 do
	local key = tostring(i)
	hl.bind(mainMod .. "+" .. key, hl.dsp.focus({ workspace = key }))
	hl.bind(secondMod .. "+" .. key, hl.dsp.window.move({ workspace = key }))
end

-- Volume controls
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- Screenshots
hl.bind(mainMod .. "+SHIFT+S", hl.dsp.exec_cmd("~/my-rice/scripts/screenshot area"))
hl.bind(mainMod .. "+S", hl.dsp.exec_cmd("~/my-rice/scripts/screenshot full"))
hl.bind(mainMod .. "+CTRL+S", hl.dsp.exec_cmd("~/my-rice/scripts/screenshot clipboard"))
