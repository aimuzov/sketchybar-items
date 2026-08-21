local M = {}

-- launchd starts sketchybar with a short PATH — homebrew plus the system directories —
-- so anything installed elsewhere is invisible to io.popen: /usr/local/bin is not
-- on it, and mise and asdf keep their tools under their own prefixes. Lua cannot
-- export a variable into its own environment, so the PATH travels as a prefix on every
-- command instead.
local search_path = table.concat({
	"/opt/homebrew/bin",
	"/opt/homebrew/sbin",
	"/usr/local/bin",
	"/usr/local/sbin",
	(os.getenv("HOME") or "") .. "/.local/share/mise/shims",
	os.getenv("PATH") or "/usr/bin:/bin:/usr/sbin:/sbin",
}, ":")

function M.safe_exec(cmd)
	local handle = io.popen("PATH='" .. search_path .. "' " .. cmd .. " 2>/dev/null")
	if not handle then
		return nil
	end
	local result = handle:read("a")
	handle:close()
	if not result or result:match("^%s*$") then
		return nil
	end
	return (result:gsub("%s+", ""))
end

-- Every lookup spawns a shell and the same tool is asked about by several items,
-- so the answers are kept.
local resolved = {}

function M.bin(cmd)
	if resolved[cmd] == nil then
		resolved[cmd] = M.safe_exec("command -v " .. cmd) or false
	end
	return resolved[cmd] or nil
end

function M.has(cmd)
	return M.bin(cmd) ~= nil
end

function M.has_all(cmds)
	for _, cmd in ipairs(cmds) do
		if not M.has(cmd) then
			return false
		end
	end
	return true
end

-- Items are copied one at a time, so whatever an item needs declared — an event, a
-- yabai signal — it has to declare itself. Several items want the same one and they
-- share a single Lua state, so the first one through does the work for the rest.
local done = {}

function M.once(key)
	if done[key] then
		return false
	end
	done[key] = true
	return true
end

-- window_focus is not a sketchybar event but a yabai signal: nothing triggers it until
-- yabai is told to, which is why the item asks for its own signal instead of expecting
-- a line in the user's yabairc.
--
-- The label is removed before it is added because yabai keeps duplicates: otherwise
-- every reload of the bar would stack another copy of the signal, and one focus change
-- would fire the event as many times as the bar had been reloaded.
function M.ensure_yabai_signal(event, trigger)
	if not M.has("yabai") then
		return false
	end

	local label = "sketchybar_" .. trigger
	local add = ("yabai -m signal --add event=%s label=%s action='sketchybar --trigger %s'"):format(
		event,
		label,
		trigger
	)

	-- The remove silences itself: on the first run there is no such label, and the
	-- 2>/dev/null safe_exec appends lands on the last command of the list, not this one
	M.safe_exec("yabai -m signal --remove " .. label .. " 2>/dev/null; " .. add)

	return true
end

function M.has_font(name)
	local found = M.safe_exec(
		"ls ~/Library/Fonts /Library/Fonts /System/Library/Fonts 2>/dev/null | grep -qi '" .. name .. "' && echo yes"
	)
	return found == "yes"
end

-- yabai answers queries only once it has finished starting, and sketchybar is usually
-- up first. Items that read a query at load time wait for it rather than drawing an
-- empty bar that never fills in.
function M.wait_for_yabai(max_wait)
	max_wait = max_wait or 10
	local elapsed = 0

	while elapsed < max_wait do
		local spaces = M.safe_exec("yabai -m query --spaces")
		if spaces and spaces:match("^%[") then
			return true
		end
		os.execute("sleep 0.5")
		elapsed = elapsed + 0.5
	end

	return false
end

return M
