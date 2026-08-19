--[[
format.lua - pure popup-text builder
]]

local M = {}

function M.popup(unit, strings, detailed)
	strings = strings or {}
	if detailed == nil then
		detailed = true
	end
	local lines = {}

	if detailed then
		local sys = unit.system and strings.systems and strings.systems[unit.system]

		if sys and strings.system_label then
			lines[#lines + 1] = strings.system_label .. ": " .. sys
		end

		local cat = unit.category and strings.categories and strings.categories[unit.category]

		if cat and strings.category_label then
			lines[#lines + 1] = strings.category_label .. ": " .. cat
		end

		if #lines > 0 then
			lines[#lines + 1] = ""
		end
	end

	for _, r in ipairs(unit.results or {}) do
		-- A result is either a "1 name = value unit" conversion or a precomputed
		-- raw line (r.text) - used where the "1 name =" template doesn't fit, e.g.
		-- temperature carries formulas ("°F = °C × 9/5 + 32") instead of a factor.
		local line = r.text or ("1 " .. unit.name .. " = " .. r.value .. " " .. r.unit)

		if r.label then
			line = line .. " - " .. r.label
		end
		lines[#lines + 1] = line
	end

	return table.concat(lines, "\n")
end

return M
