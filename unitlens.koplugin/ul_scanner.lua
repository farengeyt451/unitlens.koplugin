--[[
scanner.lua - device-side page tokenizer (KOReader / crengine)
]]

local logger = require("logger")

local M = {}

-- KOReader runs on LuaJIT (5.1 semantics), which has no `<const>` attribute.
local GUARD_SAFETY_CAP = 4000

-- Safety wrapper helper
local function try(fn)
	local ok, res = pcall(fn)

	if ok then
		return res
	end

	return nil
end

-- Get the numeric position of an XPointer
local function pos_of(doc, xp)
	return try(function()
		return doc:getPosFromXPointer(xp)
	end)
end

local DEGREE = "\194\176" -- U+00B0 "°" (2 UTF-8 bytes)

-- crengine word-navigation emits the degree sign as its OWN token ("27", "°",
-- ...) and drops the trailing C/F letter entirely - it only survives in the gap
-- text before the NEXT token. So "27 °C" arrives as {"27", "°"} with a "C " gap,
-- and neither "°" nor "C" is a symbol on its own. Recover it: for any token that
-- ends in "°", peek at the text right after it and, if it starts with C/F, glue
-- that letter on ("°" -> "°C", "20°" -> "20°C"). The matcher then sees the "°C"
-- symbol, digit-gated by the preceding "27" (or the glued number). A bare "°"
-- (e.g. "90° turn") is left untouched, so it never false-matches.
local function reattach_degree(doc, tokens)
	for i = 1, #tokens do
		local t = tokens[i]

		if t.text:sub(-2) == DEGREE then
			local nxt = tokens[i + 1]
			local after = nxt
				and try(function()
					return doc:getTextFromXPointers(t.end_xp, nxt.start_xp)
				end)
			local letter = after and after:match("^%s*([CF])")

			if letter then
				t.text = t.text .. letter
				-- The C/F is not a token of its own; it lives in the gap up to the
				-- next token. Extend the span so the underline covers "°C", not the
				-- lone "°". (Worst case it also spans a trailing space/comma.)
				t.end_xp = nxt.start_xp
			end
		end
	end
end

-- Enumerate the visible page's word tokens
function M.pageTokens(doc, page)
	local tokens = {}

	if not doc or not doc.getNextVisibleWordStart then
		logger.info("[unitlens] scanner: crengine word-nav unavailable (paged doc?)")
		return tokens
	end

	local start_xp = try(function()
		return doc:getPageXPointer(page)
	end)

	if not start_xp then
		return tokens
	end

	local start_pos = pos_of(doc, start_xp)

	local end_xp = try(function()
		return doc:getPageXPointer(page + 1)
	end)
	local end_pos = end_xp and pos_of(doc, end_xp) or nil

	if end_pos and start_pos and end_pos <= start_pos then
		end_pos = nil
	end

	local cursor = start_xp
	local guard = 0

	-- To not overflow in case API misbehaves
	while guard < GUARD_SAFETY_CAP do
		guard = guard + 1

		local wstart = try(function()
			return doc:getNextVisibleWordStart(cursor)
		end)

		if not wstart then
			break
		end

		local wend = try(function()
			return doc:getNextVisibleWordEnd(wstart)
		end)

		if not wend then
			break
		end

		-- Stop once we cross into the next page
		if end_pos then
			local wp = pos_of(doc, wstart)
			if wp and wp >= end_pos then
				break
			end
		end

		-- Extract word
		local text = try(function()
			return doc:getTextFromXPointers(wstart, wend)
		end)

		local leading_whitespace_pattern = "^%s+"
		local trailing_whitespace_pattern = "%s+$"

		if text then
			-- Trim leading/trailing whitespace
			text = text:gsub(leading_whitespace_pattern, ""):gsub(trailing_whitespace_pattern, "")
			if text ~= "" then
				tokens[#tokens + 1] = { text = text, start_xp = wstart, end_xp = wend }
			end
		end

		-- Guard against a stuck cursor
		if wend == cursor then
			local adv = try(function()
				return doc:getNextVisibleWordStart(wend)
			end)

			if not adv or adv == cursor then
				break
			end
			cursor = adv
		else
			cursor = wend
		end
	end

	reattach_degree(doc, tokens)
	return tokens
end

return M
