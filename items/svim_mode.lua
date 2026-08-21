-- Which SketchyVim mode is active, and the command line while typing one.
--
-- SketchyVim (https://github.com/FelixKratz/SketchyVim) gives every macOS text field
-- vim bindings, and it triggers `svim_update` with MODE (N/I/V/C/_) and CMDLINE.
-- Without an indicator there is nothing on screen that says whether the next key
-- will be typed or interpreted, which is the whole reason this item exists.
local sbar = require("sketchybar")
local helpers = require("helpers")
local theme = require("theme")

if not helpers.has("svim") then
	return false -- a nil result comes back from require as true, i.e. as success
end

local colors = theme.colors

local icons = {
	N = "􀀞",
	I = "􀀔",
	V = "􀀮",
	C = "􀀈",
	["_"] = "􀍷", -- operator pending
}

local mode_colors = {
	N = colors.blue,
	I = colors.green,
	V = colors.magenta,
	C = colors.orange,
	["_"] = colors.magenta,
}

-- The mode belongs to the focused text field, so it has to be redrawn when the focus
-- moves. yabai is what notices that; without it the item is still correct, just late
-- by one keystroke. See README: window_focus.
if helpers.once("event:window_focus") then
	sbar.add("event", "window_focus")
	helpers.ensure_yabai_signal("window_focused", "window_focus")
end

local svim = sbar.add("item", {
	width = 30,
	padding_left = 0,
	padding_right = 0,

	icon = {
		align = "right",
		font = { size = 18 },
		padding_left = 0,
		padding_right = 6,
	},

	label = {
		align = "left",
		font = { size = 16 },
		width = 300,
	},

	updates = true,
	position = "right",
	display = "active",
})

local function update(ENV)
	local mode = ENV.MODE or ""
	local icon = { string = icons[mode] or "", color = mode_colors[mode] or colors.white }
	-- Only command mode has anything to say beyond the icon
	local label = { string = mode == "C" and (ENV.CMDLINE or "") or "", drawing = mode == "C" }

	svim:set({ icon = icon, label = label })
end

svim:subscribe({ "svim_update", "window_focus" }, update)

return svim
