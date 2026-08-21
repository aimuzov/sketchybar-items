-- Colours and fonts every item draws with.
--
-- The defaults below are Catppuccin Macchiato and work on their own — an item can be
-- required into a bare config and will look right. To use your own palette, put a
-- `config.lua` next to your sketchybarrc that returns any of the keys below; whatever
-- it names is merged over these defaults, and anything it leaves out keeps the value
-- below.
local defaults = {
	font = "SF Pro",
	app_font = "Sketchybar App Font",
	paddings = 3,

	colors = {
		black = 0xff181926,
		white = 0xeeffffff,
		red = 0xffed8796,
		green = 0xffa6da95,
		blue = 0xff8aadf4,
		yellow = 0xffeed49f,
		orange = 0xfff5a97f,
		magenta = 0xffc6a0f6,
		grey = 0xddc6d0f5,
		transparent = 0x00000000,
		active = 0x50c6d0f5,
	},
}

local ok, user = pcall(require, "config")
if not ok or type(user) ~= "table" then
	return defaults
end

local theme = {}

for key, value in pairs(defaults) do
	if type(value) == "table" then
		theme[key] = {}
		for name, colour in pairs(value) do
			theme[key][name] = colour
		end
	else
		theme[key] = value
	end
end

for key, value in pairs(user) do
	if type(value) == "table" and type(theme[key]) == "table" then
		for name, colour in pairs(value) do
			theme[key][name] = colour
		end
	else
		theme[key] = value
	end
end

return theme
