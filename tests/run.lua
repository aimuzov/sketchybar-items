-- Runs every item without sketchybar and without any of the tools they watch:
-- `sketchybar` and `helpers` are answered by stubs, so what is under test is the
-- decision each item makes — load and draw, or step aside.
--
--   lua tests/run.lua        (from the repository root)
local root = os.getenv("ITEMS_ROOT") or "."
package.path = root .. "/?.lua;" .. package.path

local passed, failed = 0, 0

local function check(name, condition)
	if condition then
		passed = passed + 1
		print("ok " .. (passed + failed) .. " — " .. name)
	else
		failed = failed + 1
		print("not ok " .. (passed + failed) .. " — " .. name)
	end
end

-- What the stubbed sketchybar recorded during the last load
local added

local function stub_sketchybar()
	added = {}

	local function element(kind)
		local self = {}
		function self:set() end
		function self:subscribe() end
		return self
	end

	package.loaded["sketchybar"] = {
		add = function(kind)
			table.insert(added, kind)
			return element(kind)
		end,
		exec = function() end,
		default = function() end,
		bar = function()
			return element("bar")
		end,
	}
end

local function stub_helpers(installed)
	local present = {}
	for _, tool in ipairs(installed) do
		present[tool] = true
	end

	package.loaded["helpers"] = {
		has = function(tool)
			return present[tool] == true
		end,
		has_all = function(tools)
			for _, tool in ipairs(tools) do
				if not present[tool] then
					return false
				end
			end
			return true
		end,
		bin = function(tool)
			return present[tool] and ("/stub/bin/" .. tool) or nil
		end,
		has_font = function()
			return true
		end,
		-- Whoever asks first gets to declare the event or the yabai signal
		once = function()
			return true
		end,
		ensure_yabai_signal = function()
			return true
		end,
		-- Enough for the queries the items make at load time
		safe_exec = function(cmd)
			if cmd:match("length") then
				return "3"
			end
			return "stub"
		end,
		wait_for_yabai = function()
			return true
		end,
	}
end

local function load_item(name, installed)
	stub_sketchybar()
	stub_helpers(installed)
	package.loaded["theme"] = nil
	package.loaded["items." .. name] = nil

	local ok, result = pcall(require, "items." .. name)
	return ok, result, added
end

-- name → the tools it needs before it will draw anything
local items = {
	{ name = "skhd_mode", needs = { "skhd" } },
	{ name = "svim_mode", needs = { "svim" } },
	{ name = "keyboard_layout", needs = { "im-select" } },
	{ name = "input", needs = { "im-select", "svim" } },
	{ name = "yabai_window", needs = { "yabai", "jq" } },
	{ name = "yabai_spaces", needs = { "yabai", "jq" } },
	{ name = "caffeinate", needs = { "caffeinate" } },
	{ name = "battery", needs = { "pmset" } },
}

for _, item in ipairs(items) do
	local ok, result, drawn = load_item(item.name, item.needs)
	check(item.name .. " loads when its tools are installed", ok and result ~= nil)
	check(item.name .. " adds something to the bar", ok and #drawn > 0)

	-- An item that cannot work returns false rather than raising: a config that
	-- requires it unconditionally still starts.
	local ok_bare, result_bare, drawn_bare = load_item(item.name, {})
	check(item.name .. " steps aside when nothing it needs is installed", ok_bare and result_bare == false)
	check(item.name .. " adds nothing to the bar without its tools", ok_bare and #drawn_bare == 0)
end

-- An item that watches nothing has no second direction to test: there is no tool for
-- it to miss, so it draws whatever it is given
for _, name in ipairs({ "datetime" }) do
	local ok, result, drawn = load_item(name, {})
	check(name .. " loads with no tools installed at all", ok and result ~= nil and result ~= false)
	check(name .. " adds something to the bar anyway", ok and #drawn > 0)
end

-- The combined item is the one that has to survive half of its tools missing
for _, half in ipairs({ "im-select", "svim" }) do
	local ok, result, drawn = load_item("input", { half })
	check("input still loads with only " .. half, ok and result ~= nil and #drawn > 0)
end

-- theme.lua merges a user config over the defaults rather than replacing them
package.loaded["theme"] = nil
package.loaded["config"] = { colors = { red = 0xdeadbeef } }
local theme = require("theme")
check("a user colour wins over the default", theme.colors.red == 0xdeadbeef)
check("colours the user did not name keep their default", theme.colors.blue == 0xff8aadf4)
check("non-colour settings keep their default", theme.app_font == "Sketchybar App Font")

print("")
print(string.format("%d checks, %d failed", passed + failed, failed))
os.exit(failed == 0 and 0 or 1)
