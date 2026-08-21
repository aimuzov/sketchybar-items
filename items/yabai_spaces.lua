-- One entry per yabai space, showing which apps live on it.
--
-- Spaces are read from yabai once at start-up, so the bar has as many entries as the
-- machine has spaces. Each entry follows `space_windows_change` and lists its windows
-- as glyphs of sketchybar-app-font (https://github.com/kvndrsslr/sketchybar-app-font);
-- with the font missing the entry falls back to the label yabai gave the space, which
-- is what an empty space shows anyway.
--
-- Clicks are wired to yabai: left focuses the space, right destroys it.
local sbar = require("sketchybar")
local helpers = require("helpers")
local theme = require("theme")

if not helpers.has_all({ "yabai", "jq" }) then
	return false -- a nil result comes back from require as true, i.e. as success
end

local colors = theme.colors

local number_icons = {
	"􀀻",
	"􀀽",
	"􀀿",
	"􀁁",
	"􀁃",
	"􀁅",
	"􀁇",
	"􀁉",
	"􀁋",
	"􀔔",
	"􀔕",
	"􀔖",
	"􀔗",
	"􀔘",
	"􀔙",
	"􀔚",
}

local has_app_font = helpers.has_font(theme.app_font)

-- sketchybar is usually up before yabai answers queries; without this the bar would
-- be built from zero spaces and stay that way until the next reload.
helpers.wait_for_yabai()

local count = tonumber(helpers.safe_exec("yabai -m query --spaces | jq 'length'")) or 0
local spaces = {}

-- Asked for once per space and kept, the way helpers.bin keeps its lookups: a label is
-- only wanted for an empty space, and the query costs two processes in the bar's own
-- event loop. Renaming a space needs a reload to show up, which is true of adding one
-- anyway — the count above is read at start-up too.
local labels = {}

local function space_label(index)
	if labels[index] == nil then
		-- query --spaces answers with an array in space order, so space N sits at N - 1
		labels[index] = helpers.safe_exec("yabai -m query --spaces | jq -r '.[" .. (index - 1) .. "].label'")
			or false
	end
	return labels[index] or nil
end

for index = 1, count do
	local space = sbar.add("space", {
		icon = { padding_left = 6, string = "" },
		label = { padding_right = 6, font = theme.app_font .. ":Regular:16" },
		space = index,
		padding_left = 0,
		padding_right = 0,
		background = { color = colors.transparent },
	})

	spaces[index] = space

	space:subscribe("space_change", function(ENV)
		space:set({
			icon = { highlight = ENV.SELECTED },
			label = { highlight = ENV.SELECTED },
			background = { color = ENV.SELECTED == "true" and colors.active or colors.transparent },
		})
	end)

	space:subscribe("mouse.clicked", function(ENV)
		local op = (ENV.BUTTON == "right") and "--destroy" or "--focus"
		sbar.exec("yabai -m space " .. op .. " " .. ENV.SID)
	end)

end

-- sketchybar sends space_windows_change once per space, and every subscriber gets all
-- of them: with the handler on each entry a single change woke it N² times, N of those
-- for the entry it was attached to. The payload names the space, so one subscription
-- reaches every entry — and the first one carries it for the rest.
if spaces[1] then
	spaces[1]:subscribe("space_windows_change", function(ENV)
		local item = spaces[ENV.INFO.space]

		if not item then
			return
		end

		local icon = number_icons[tonumber(ENV.INFO.space)] or ""
		local apps = ""

		if has_app_font then
			for app in pairs(ENV.INFO.apps) do
				apps = apps .. app .. " "
			end
		end

		-- An empty space says what it is for instead of showing nothing
		if apps == "" then
			local label = space_label(ENV.INFO.space)

			if label then
				icon = icon .. " " .. label
			end
		end

		item:set({
			icon = { string = icon },
			label = { string = apps, padding_left = apps == "" and 0 or 3 },
		})
	end)
end

return spaces
