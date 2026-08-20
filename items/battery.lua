-- Battery charge, and whether it is on the charger.
--
-- pmset is the only thing macOS offers that reports both without a private API, and
-- it answers in prose ("98%; discharging; 4:41 remaining"), so the number is picked
-- out with a pattern rather than parsed.
local sbar = require("sketchybar")
local helpers = require("helpers")
local colors = require("theme").colors

if not helpers.has("pmset") then
	return false -- see README: an item with a missing tool returns false, not an error
end

local icons = {
	percents_100 = "􀛨",
	percents_75 = "􀺸",
	percents_50 = "􀺶",
	percents_25 = "􀛩",
	percents_0 = "􀛪",
	charging = "􀢋",
}

local battery = sbar.add("item", {
	position = "right",
	label = { drawing = true },
	update_freq = 120,
})

local function update()
	-- safe_exec strips every space out of what it reads, so pmset's "AC Power"
	-- arrives as "ACPower" — matching the spaced form would never charge the icon
	local batt_info = helpers.safe_exec("pmset -g batt") or ""
	local charge = tonumber(batt_info:match("(%d+)%%"))

	local label = ""
	local icon = { string = "!", color = colors.white }

	if charge then
		label = charge .. "%"

		if charge > 80 then
			icon.string = icons.percents_100
		elseif charge > 60 then
			icon.string = icons.percents_75
		elseif charge > 40 then
			icon.string = icons.percents_50
			icon.color = colors.yellow
		elseif charge > 20 then
			icon.string = icons.percents_25
			icon.color = colors.orange
		elseif charge > 0 then
			icon.string = icons.percents_0
			icon.color = colors.red
		end
	end

	if batt_info:find("ACPower") then
		icon.string = icons.charging
	end

	battery:set({ icon = icon, label = label })
end

-- power_source_change fires on plug and unplug, system_woke because the charge read
-- before sleep is stale by the time the lid opens
battery:subscribe({ "routine", "power_source_change", "system_woke" }, update)

return battery
