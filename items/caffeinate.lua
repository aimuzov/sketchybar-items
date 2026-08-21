-- Keeps the display awake, click to toggle.
--
-- The PID goes into a file under /tmp, named after the user, so the item
-- stops only what it started: `killall caffeinate` would also end the one
-- a long build is relying on.
--
-- The icon is polled, not trusted after a click: the process outlives a
-- sketchybar reload, and a `kill` from a terminal never reaches the bar.
local sbar = require("sketchybar")
local helpers = require("helpers")
local colors = require("theme").colors

if not helpers.has("caffeinate") then
	return false -- a nil result comes back from require as true, i.e. as success
end

local pidfile = "/tmp/sketchybar-caffeinate-" .. (os.getenv("USER") or "shared") .. ".pid"

-- -di keeps both the display and the system awake
local start_cmd = helpers.bin("caffeinate") .. " -di & echo $! > " .. pidfile
local stop_cmd = 'kill "$(cat ' .. pidfile .. ' 2>/dev/null)" 2>/dev/null; rm -f ' .. pidfile

local icons = {
	off = "􀆻",
	on = "􀆼",
}

local caffeinate = sbar.add("item", {
	position = "right",
	icon = { string = icons.off, font = { size = 16 } },
	label = { drawing = false },
	update_freq = 30,
})

local active = false

local function is_active()
	local pid = helpers.safe_exec("cat " .. pidfile)
	if not pid then
		return false
	end
	-- signal 0 asks whether the process is alive without touching it
	return helpers.safe_exec("kill -0 " .. pid .. " && echo yes") == "yes"
end

local function render()
	caffeinate:set({
		icon = {
			string = active and icons.on or icons.off,
			color = active and colors.yellow or colors.white,
		},
	})
end

local function reconcile()
	active = is_active()
	render()
end

caffeinate:subscribe({ "routine", "forced" }, reconcile)

caffeinate:subscribe("mouse.clicked", function()
	sbar.exec(active and stop_cmd or start_cmd)
	active = not active
	render() -- immediate feedback; the next tick confirms it
end)

return caffeinate
