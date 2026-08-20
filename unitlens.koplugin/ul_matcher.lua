--[[
matcher.lua - pure matching over a token array

Returns a list of matches: { unit = unitdef, from = i, to = i, token = tok }
]]

local util = require("ul_util")

local M = {}

-- Glued number+unit inside ONE token (e.g. "600мм", "12°C", "2,5кг").
-- Off-device the tokenizer pre-splits these, but crengine hands the whole
-- thing over as a single word, so the neighbour-based digit gate never sees a
-- separate number. Peel a leading numeric run (integer or decimal) and test the
-- remainder against the dictionary; the number's presence IS the digit gate, so
-- symbols are allowed here just like "600 мм". Returns the unit def or nil.
function M.split_glued(dict, tok)
	local rest = tok:match("^%d[%d.,]*(.+)$")

	if not rest then
		return nil
	end

	return dict.forms[util.casefold(rest)] or dict.symbols[rest]
end

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
			else
				-- No whole-token hit: try the glued number+unit form. The match
				-- stays anchored to the whole token (from == to == i), so the
				-- renderer underlines the entire "600мм" with the span it already
				-- has - no sub-word XPointer arithmetic needed.
				local glued = M.split_glued(dict, tok)

				if glued then
					matches[#matches + 1] = { unit = glued, from = i, to = i, token = tok }
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
