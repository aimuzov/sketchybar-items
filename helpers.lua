local M = {}

-- launchd starts sketchybar with a short PATH — homebrew plus the system directories —
-- so anything installed elsewhere is invisible to io.popen: the tailscale CLI lives in
-- /usr/local/bin, mise and asdf keep their tools under their own prefixes. Lua cannot
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
