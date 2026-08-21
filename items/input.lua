-- Keyboard layout and SketchyVim mode in one badge.
--
-- Both answer the same question — what happens when I press a key — so they share a
-- slot: with no mode reported the layout stands alone, and as soon as SketchyVim
-- names one the badge takes that mode's colour and icon. In command mode the label
-- carries the command line being typed, next to the layout.
--
-- Either half may be missing. With only im-select installed this is the layout
-- indicator; with only SketchyVim it is the mode indicator; with neither the item
-- does not load at all.
local sbar = require("sketchybar")
local helpers = require("helpers")
local theme = require("theme")

local has_layout = helpers.has("im-select")
local has_svim = helpers.has("svim")

if not has_layout and not has_svim then
	return false -- a nil result comes back from require as true, i.e. as success
end

local colors = theme.colors

local kb_icons = {
	["com.apple.keylayout.US"] = "􀀅",
	["com.apple.keylayout.Russian"] = "􀀦",
}

local kb_unknown = "􀁝"

local svim_icons = {
	N = "􀀞",
	I = "􀀔",
	V = "􀀮",
	C = "􀀈",
	["_"] = "􀍷",
}

local svim_colors = {
	N = colors.blue,
	I = colors.green,
	V = colors.magenta,
	C = colors.orange,
	["_"] = colors.magenta,
}

-- keyboard_layout asks for the same event, and adding it twice is what the once guard
-- is for. Behind has_layout as well: with no im-select there is no layout half to feed.
if has_layout and helpers.once("event:keyboard_layout_change") then
	sbar.add("event", "keyboard_layout_change", "AppleSelectedInputSourcesChangedNotification")
end

-- The SketchyVim half has to be redrawn when the focus moves to another text field,
-- and yabai is what notices that. See README: window_focus.
if has_svim and helpers.once("event:window_focus") then
	sbar.add("event", "window_focus")
	helpers.ensure_yabai_signal("window_focused", "window_focus")
end

local input = sbar.add("item", {
	display = "active",
	position = "right",
	updates = true,
	label = { align = "center", padding_left = 3, padding_right = 6, font = { size = 17 }, y_offset = 1 },
	icon = { align = "center", padding_left = 3, padding_right = 0, font = { size = 17 }, y_offset = 1 },
})

local state = {
	kb_icon = has_layout and kb_unknown or "",
	kb_color = colors.white,
	svim_mode = nil,
	svim_cmdline = nil,
}

local function render()
	local icon = { string = state.kb_icon, color = colors.black, width = "dynamic" }
	local label = { string = state.kb_icon, color = colors.black, width = "dynamic" }
	local background = { color = colors.transparent }

	if state.svim_mode and svim_icons[state.svim_mode] then
		icon.string = svim_icons[state.svim_mode]
		background.color = svim_colors[state.svim_mode]

		if state.svim_mode == "C" and state.svim_cmdline then
			label.string = state.kb_icon .. " " .. svim_icons.C .. " " .. state.svim_cmdline
		end
	else
		-- No mode to show: the layout alone, drawn in its own colour rather than
		-- as text on a coloured badge
		icon.string = ""
		icon.width = 0
		label.color = state.kb_color
	end

	input:set({ icon = icon, label = label, background = background })
end

local function on_keyboard()
	local layout = helpers.safe_exec("im-select") or ""

	state.kb_icon = kb_icons[layout] or kb_unknown
	state.kb_color = colors.white

	render()
end

local function on_svim(ENV)
	if ENV.MODE and ENV.MODE ~= "" then
		state.svim_mode = ENV.MODE
		state.svim_cmdline = ENV.CMDLINE
	else
		state.svim_mode = nil
		state.svim_cmdline = nil
	end

	render()
end

if has_layout then
	input:subscribe({ "forced", "keyboard_layout_change" }, on_keyboard)
end

if has_svim then
	input:subscribe({ "svim_update", "window_focus" }, on_svim)
end

return input
