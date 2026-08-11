--[[
scanner.lua — device-side page tokenizer (KOReader / crengine).

Walks the current visible page into word tokens with XPointer spans using
crengine word-navigation, which is Unicode-correct and done in C. This is the
on-device counterpart to util.tokenize (which is off-device/tests only): here we
get proper word boundaries for free AND the XPointers we need for rendering (M3).

Returns an array of tokens:  { text = <string>, start_xp = <xp>, end_xp = <xp> }

Everything is guarded with pcall — crengine word-nav only exists for reflowable
(EPUB/FB2/…) documents, not paged PDF/DjVu.
]]

local logger = require("logger")

local M = {}

local function try(fn)
	local ok, res = pcall(fn)
	if ok then
		return res
	end
	return nil
end

local function pos_of(doc, xp)
	return try(function()
		return doc:getPosFromXPointer(xp)
	end)
end

-- Enumerate the visible page's word tokens.
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
	-- Boundary: start of the next page (nil on the last page).
	local end_xp = try(function()
		return doc:getPageXPointer(page + 1)
	end)
	local end_pos = end_xp and pos_of(doc, end_xp) or nil

	local cursor = start_xp
	local guard = 0
	while guard < 4000 do
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

		-- Stop once we cross into the next page.
		if end_pos then
			local wp = pos_of(doc, wstart)
			if wp and wp >= end_pos then
				break
			end
		end

		local text = try(function()
			return doc:getTextFromXPointers(wstart, wend)
		end)
		if text then
			text = text:gsub("^%s+", ""):gsub("%s+$", "")
			if text ~= "" then
				tokens[#tokens + 1] = { text = text, start_xp = wstart, end_xp = wend }
			end
		end

		-- Advance; guard against a stuck cursor.
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

	return tokens
end

return M
