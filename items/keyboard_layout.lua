-- The current keyboard layout.
--
-- macOS posts AppleSelectedInputSourcesChangedNotification on every layout switch,
-- which sketchybar can subscribe to directly, so nothing is polled. The layout id
-- itself is read with im-select (`brew install im-select`).
--
-- Add your own layouts to `icons` below; `im-select` prints the id to use as the key.
local sbar = require("sketchybar")
local helpers = require("helpers")
local theme = require("theme")

if not helpers.has("im-select") then
	return false -- see README: an item with a missing tool returns false, not an error
end

local colors = theme.colors

local icons = {
	["com.apple.keylayout.US"] = { glyph = "􀀅" },
	["com.apple.keylayout.Russian"] = { glyph = "􀀦", color = colors.red },
}

local unknown = { glyph = "􀁝", color = colors.white }

local keyboard_layout = sbar.add("item", {
	icon = { font = { size = 18 } },
	padding_left = 0,
	padding_right = 0,
	display = "active",
	position = "right",
})

local function update()
	local layout = icons[helpers.safe_exec("im-select") or ""] or unknown

	keyboard_layout:set({
		icon = { string = layout.glyph, color = layout.color or colors.white },
	})
end

sbar.add("event", "keyboard_layout_change", "AppleSelectedInputSourcesChangedNotification")
keyboard_layout:subscribe({ "forced", "keyboard_layout_change" }, update)

return keyboard_layout
