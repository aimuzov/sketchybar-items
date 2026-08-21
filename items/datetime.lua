-- The date and the time.
--
-- The only item here that watches nothing: os.date answers from the C library, so
-- there is no tool to look for, no check to make and nothing to step aside for.
local sbar = require("sketchybar")

local datetime = sbar.add("item", {
	position = "right",
	update_freq = 30,
	label = { font = { style = "Semibold" } },
})

local function update()
	datetime:set({ icon = os.date("%a %d %b"), label = os.date("%H:%M") })
end

datetime:subscribe({ "routine", "forced" }, update)

return datetime
