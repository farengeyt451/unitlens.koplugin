--[[
format.lua - pure popup-text builder

Given a matched unit and the active dict's `strings` block, assemble the popup
]]

local M = {}

function M.popup(unit, strings)
	strings = strings or {}
	local lines = {}

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

	for _, r in ipairs(unit.results or {}) do
		local line = "1 " .. unit.name .. " = " .. r.value .. " " .. r.unit

		if r.label then
			line = line .. " - " .. r.label
		end
		lines[#lines + 1] = line
	end

	return table.concat(lines, "\n")
end

return M
