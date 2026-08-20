-- The date and the time.
--
-- The only item here that watches nothing: os.date answers from the C library, so
-- there is no tool to look for and nothing to step aside for. Every other item in
-- this repository returns false when what it reports on is missing; this one has
-- no such case and always draws.
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
