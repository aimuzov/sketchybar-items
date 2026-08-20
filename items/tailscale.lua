-- Whether tailscale is up, down, or waiting to be logged in.
--
-- The state is read from `tailscale status --json`, which answers locally without
-- touching the network. Besides the routine refresh the item listens for a
-- `tailscale_status_update` event, so a script that toggles the connection can push
-- the change instead of waiting for the next poll:
--
--   sketchybar --trigger tailscale_status_update
local sbar = require("sketchybar")
local helpers = require("helpers")

if not helpers.has_all({ "tailscale", "jq" }) then
	return false -- see README: an item with a missing tool returns false, not an error
end

local icons = {
	Running = "􀞿",
	Stopped = "􀞾",
	NeedsLogin = "􀺇",
	Unknown = "􀧸",
}

if helpers.once("event:tailscale_status_update") then
	sbar.add("event", "tailscale_status_update")
end

local tailscale = sbar.add("item", {
	padding_right = 0,
	position = "right",
})

-- Resolved once: the CLI ships inside the app on some machines (/usr/local/bin) and
-- comes from homebrew on others, so the path is asked for rather than assumed.
local cmd = helpers.bin("tailscale") .. " status --json | jq -r '.BackendState'"

local function update()
	tailscale:set({ icon = icons[helpers.safe_exec(cmd) or ""] or icons.Unknown })
end

tailscale:subscribe({ "routine", "forced", "tailscale_status_update" }, update)

return tailscale
