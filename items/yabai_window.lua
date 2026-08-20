-- What yabai is doing with the focused window: floating, zoomed, or one of a stack.
--
-- A tiling layout hides its own state — a stacked window looks exactly like a single
-- one, and a zoomed window looks like an empty space. This item names it, and for a
-- stack it also says which of how many windows you are looking at (2 / 4).
local sbar = require("sketchybar")
local helpers = require("helpers")
local theme = require("theme")

if not helpers.has_all({ "yabai", "jq" }) then
	return false -- see README: an item with a missing tool returns false, not an error
end

local colors = theme.colors

local icons = {
	stack = "􃑷",
	fullscreen_zoom = "􀏜",
	parent_zoom = "􀥃",
	float = "􀢌",
}

-- Nothing in yabai reports a focus change to sketchybar on its own, so the item asks
-- for the signal that feeds it. See README: window_focus.
if helpers.once("event:window_focus") then
	sbar.add("event", "window_focus")
	helpers.ensure_yabai_signal("window_focused", "window_focus")
end

local yabai = sbar.add("item", {
	display = "active",
	icon = { width = 0 },
	position = "left",
})

local function window_prop(name, window)
	window = window or ""
	return helpers.safe_exec("yabai -m query --windows --window " .. window .. " | jq '.[\"" .. name .. "\"]'")
end

local function update()
	local icon = { string = "", width = 0, color = colors.white }
	local label = { string = "", width = 0, color = colors.white, font = { style = "Semibold" } }

	if window_prop("is-floating") == "true" then
		icon.string = icons.float
		icon.color = colors.red
	elseif window_prop("has-fullscreen-zoom") == "true" then
		icon.string = icons.fullscreen_zoom
		icon.color = colors.green
	elseif window_prop("has-parent-zoom") == "true" then
		icon.string = icons.parent_zoom
		icon.color = colors.blue
	else
		local index = window_prop("stack-index")
		local position = tonumber(index)

		-- stack-index is 0 for a window that is not stacked at all
		if position and position > 0 then
			icon.string = icons.stack
			icon.color = colors.magenta
			label.string = index .. " / " .. (window_prop("stack-index", "stack.last") or "")
			label.width = 40
		end
	end

	if icon.string ~= "" then
		icon.width = 30
	end

	yabai:set({ icon = icon, label = label })
end

yabai:subscribe("window_focus", update)

return yabai
