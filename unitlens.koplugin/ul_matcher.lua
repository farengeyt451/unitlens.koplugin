--[[
matcher.lua — pure matching over a token array

Returns a list of matches: { unit = unitdef, from = i, to = i, token = tok }
]]

local util = require("ul_util")

local M = {}

function M.match(dict, tokens)
	local matches = {}

	for i, tok in ipairs(tokens) do
		local unit = dict.forms[util.casefold(tok)]

		if unit then
			matches[#matches + 1] = { unit = unit, from = i, to = i, token = tok }
		else
			local sym = dict.symbols[tok]

			if sym then
				local prev_num = i > 1 and util.is_number(tokens[i - 1])
				local next_num = i < #tokens and util.is_number(tokens[i + 1])

				if prev_num or next_num then
					matches[#matches + 1] = { unit = sym, from = i, to = i, token = tok }
				end
			end
		end
	end
	return matches
end

-- Convenience for tests / logging: tokenize raw text, then match
function M.match_text(dict, text)
	return M.match(dict, util.tokenize(text))
end

return M
