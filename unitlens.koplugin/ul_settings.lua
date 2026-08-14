--[[
ul_settings.lua - global appearance settings, backed by G_reader_settings
]]

local M = {}

local PREFIX = "unitlens_"

M.DEFAULTS = {
	enabled = true,
	underline_style = "wavy", -- wavy | solid | dotted | dashed | double | none
	underline_thickness = 2, -- 1 | 2 | 3 (px, pre-scaling)
	underline_intensity = "medium", -- light | medium | dark
	tooltip_timeout = 4, -- 2 | 4 | 8 | 0 (0 = never), seconds
	tooltip_text_size = "auto", -- auto (follow book) | smaller | larger | largest (relative nudge)
	ui_lang = "auto", -- "auto" (follow KOReader) or a shipped l10n code (en/ru/es/…)
}

function M.get(key)
	local def = M.DEFAULTS[key]

	if not G_reader_settings then
		return def
	end

	local v = G_reader_settings:readSetting(PREFIX .. key)

	if v == nil then
		return def
	end
	return v
end

function M.set(key, value)
	if G_reader_settings then
		G_reader_settings:saveSetting(PREFIX .. key, value)
	end
end

function M.all()
	local out = {}

	for key in pairs(M.DEFAULTS) do
		out[key] = M.get(key)
	end
	return out
end

return M
