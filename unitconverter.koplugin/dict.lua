--[[
dict.lua — pure dictionary loader

Takes a raw dictionary table (as returned by dicts/xx.lua) and compiles it into
flat lookup maps for O(1) matching
]]

local util = require("util")

local M = {}

-- Compile a raw dict: { lang, name, strings, units = { key = unitdef } }
function M.compile(raw)
	local forms = {}
	local symbols = {}

	for key, unit in pairs(raw.units or {}) do
		unit.key = key

		for _, form in ipairs(unit.forms or {}) do
			forms[util.casefold(form)] = unit
		end

		-- Symbols stay case-sensitive on purpose (m/M, in/IN collide otherwise)
		for _, sym in ipairs(unit.symbols or {}) do
			symbols[sym] = unit
		end
	end

	return {
		lang = raw.lang,
		name = raw.name,
		strings = raw.strings or {},
		units = raw.units or {},
		forms = forms,
		symbols = symbols,
	}
end

return M
