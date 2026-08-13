--[[
ul_menu.lua — builds the "Unit Lens menu
]]

local _ = require("gettext")
local langselect = require("ul_langselect")

local M = {}

-- A radio group over one plugin.opts key. `choices` = { { text, value }, ... }
local function radio_group(plugin, key, choices)
	local sub = {}

	for _, c in ipairs(choices) do
		sub[#sub + 1] = {
			text = c.text,
			radio = true,
			checked_func = function()
				return plugin.opts[key] == c.value
			end,
			callback = function()
				plugin:setOpt(key, c.value)
			end,
			keep_menu_open = true,
		}
	end

	return sub
end

function M.build(plugin)
	return {
		text = _("Unit Lens"),
		sorting_hint = "more_tools",
		sub_item_table = {
			{
				text = _("Highlight measurement units"),
				checked_func = function()
					return plugin.enabled
				end,
				callback = function()
					plugin:setEnabled(not plugin.enabled)
				end,
				keep_menu_open = true,
			},
			{
				text = _("Language"),
				sub_item_table_func = function()
					return langselect.menuItems(plugin)
				end,
			},
			{
				text = _("Underline style"),
				separator = true,
				sub_item_table = radio_group(plugin, "underline_style", {
					{ text = _("Wavy"), value = "wavy" },
					{ text = _("Solid"), value = "solid" },
					{ text = _("Dotted"), value = "dotted" },
					{ text = _("Dashed"), value = "dashed" },
					{ text = _("Double"), value = "double" },
					{ text = _("None"), value = "none" },
				}),
			},
			{
				text = _("Underline thickness"),
				sub_item_table = radio_group(plugin, "underline_thickness", {
					{ text = _("1 px"), value = 1 },
					{ text = _("2 px"), value = 2 },
					{ text = _("3 px"), value = 3 },
				}),
			},
			{
				text = _("Underline intensity"),
				sub_item_table = radio_group(plugin, "underline_intensity", {
					{ text = _("Light"), value = "light" },
					{ text = _("Medium"), value = "medium" },
					{ text = _("Dark"), value = "dark" },
				}),
			},
			{
				text = _("Tooltip timeout"),
				separator = true,
				sub_item_table = radio_group(plugin, "tooltip_timeout", {
					{ text = _("2 seconds"), value = 2 },
					{ text = _("4 seconds"), value = 4 },
					{ text = _("8 seconds"), value = 8 },
					{ text = _("Never"), value = 0 },
				}),
			},
			{
				text = _("About"),
				keep_menu_open = true,
				callback = function()
					plugin:showAbout()
				end,
			},
		},
	}
end

return M
