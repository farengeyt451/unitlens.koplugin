--[[
ul_menu.lua - builds the "Unit Lens" menu
]]

local langselect = require("ul_langselect")
local i18n = require("ul_i18n")

local M = {}

local t = i18n.t

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
		text = "Unit Lens", -- brand, not translated
		-- Placed at the top of the Tools tab via reader_menu_order (see main.lua);
		-- sorting_hint is the fallback that would otherwise append us as an orphan
		sorting_hint = "tools",
		sub_item_table = {
			{
				text = t("Highlight measurement units"),
				checked_func = function()
					return plugin.enabled
				end,
				callback = function()
					plugin:setEnabled(not plugin.enabled)
				end,
				keep_menu_open = true,
			},
			{
				text = t("Book language"),
				sub_item_table_func = function()
					return langselect.menuItems(plugin)
				end,
			},
			{
				text = t("Interface language"),
				separator = true,
				sub_item_table_func = function()
					return i18n.menuItems(plugin)
				end,
			},
			{
				text = t("Underline style"),
				sub_item_table = radio_group(plugin, "underline_style", {
					{ text = t("Wavy"), value = "wavy" },
					{ text = t("Solid"), value = "solid" },
					{ text = t("Dotted"), value = "dotted" },
					{ text = t("Dashed"), value = "dashed" },
					{ text = t("Double"), value = "double" },
					{ text = t("None"), value = "none" },
				}),
			},
			{
				text = t("Underline thickness"),
				sub_item_table = radio_group(plugin, "underline_thickness", {
					{ text = t("1 px"), value = 1 },
					{ text = t("2 px"), value = 2 },
					{ text = t("3 px"), value = 3 },
				}),
			},
			{
				text = t("Underline intensity"),
				sub_item_table = radio_group(plugin, "underline_intensity", {
					{ text = t("Light"), value = "light" },
					{ text = t("Medium"), value = "medium" },
					{ text = t("Dark"), value = "dark" },
				}),
			},
			{
				text = t("Tooltip timeout"),
				sub_item_table = radio_group(plugin, "tooltip_timeout", {
					{ text = t("2 seconds"), value = 2 },
					{ text = t("4 seconds"), value = 4 },
					{ text = t("8 seconds"), value = 8 },
					{ text = t("Never"), value = 0 },
				}),
			},
			{
				text = t("Tooltip text size"),
				separator = true,
				sub_item_table = radio_group(plugin, "tooltip_text_size", {
					{ text = t("Auto (follow book)"), value = "auto" },
					{ text = t("Smaller"), value = "smaller" },
					{ text = t("Larger"), value = "larger" },
					{ text = t("Largest"), value = "largest" },
				}),
			},
			{
				text = t("About"),
				keep_menu_open = true,
				callback = function()
					plugin:showAbout()
				end,
			},
		},
	}
end

return M
