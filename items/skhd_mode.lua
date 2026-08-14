-- Which skhd mode is active, as a coloured badge.
--
-- skhd has modal bindings (`:: window`, `:: resize`, …) and nothing on screen says
-- which one you are in. The mode name arrives as a sketchybar event that skhdrc
-- triggers on every mode switch:
--
--   :: window @ : sketchybar --trigger skhd_mode_update MODE=window
--   :: default : sketchybar --trigger skhd_mode_update MODE=
--
-- An empty MODE clears the badge, which is what leaving a mode should look like.
local sbar = require("sketchybar")
local helpers = require("helpers")
local theme = require("theme")

if not helpers.has("skhd") then
	return false -- see README: an item with a missing tool returns false, not an error
end

local colors = theme.colors

-- SF Symbols; replace with anything your bar font has
local icons = {
	window = "􀏜",
	resize = "􀄭",
	move = "􀭱",
	stack = "􃑷",
	command = "􀆔",
}

local mode_colors = {
	window = colors.yellow,
	resize = colors.orange,
	move = colors.green,
	stack = colors.magenta,
	command = colors.red,
}

sbar.add("event", "skhd_mode_update")

local skhd = sbar.add("item", {
	display = "active",
	position = "left",
	icon = { width = 0, align = "center", padding_left = 0, padding_right = 0 },
	label = { width = 0, padding_left = 0, padding_right = 0 },
})

local function update(ENV)
	local mode = ENV.MODE or ""
	local icon = { string = "", width = 0, color = colors.black, padding_right = 0 }
	local background = { color = colors.transparent }

	if icons[mode] then
		icon.string = icons[mode]
		icon.width = 44
		icon.padding_right = mode == "window" and 2 or 0
		background.color = mode_colors[mode]
	end

	skhd:set({ icon = icon, background = background })
end

skhd:subscribe("skhd_mode_update", update)

return skhd
