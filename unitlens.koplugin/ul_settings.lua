--[[
ul_settings.lua — global appearance settings, backed by G_reader_settings.

Keys are namespaced `unitlens_`. The language choice is intentionally NOT here —
it is per-book and lives in the document sidecar (see ul_langselect.lua).

Usage:
  local settings = require("ul_settings")
  local style = settings.get("underline_style")   -- returns default if unset
  settings.set("underline_style", "solid")
  local opts = settings.all()                       -- table of every key
]]

local M = {}

local PREFIX = "unitlens_"

M.DEFAULTS = {
	enabled = true,
	underline_style = "wavy", -- wavy | solid | dotted | dashed | double | none
	underline_thickness = 2, -- 1 | 2 | 3 (px, pre-scaling)
	underline_intensity = "medium", -- light | medium | dark
	tooltip_timeout = 4, -- 2 | 4 | 8 | 0 (0 = never), seconds
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
