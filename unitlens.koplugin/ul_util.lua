--[[
util.lua - pure text helpers (no KOReader UI dependency)
]]

local M = {}

-- Resolve a full-Unicode lowercase
local casefold
do
	local ok_utf8proc, Utf8Proc = pcall(require, "ffi/utf8proc")
	if ok_utf8proc and Utf8Proc and Utf8Proc.lowercase then
		casefold = function(s)
			return Utf8Proc.lowercase(s)
		end
	else
		local ok_luautf8, lutf8 = pcall(require, "lua-utf8")
		if ok_luautf8 and lutf8 and lutf8.lower then
			casefold = function(s)
				return lutf8.lower(s)
			end
		else
			error(
				"unitlens/util: no Unicode lowercaser found - expected KOReader's "
					.. "'ffi/utf8proc' on device, or luautf8 for off-device tests "
					.. "(`luarocks install --local luautf8`)."
			)
		end
	end
end

M.casefold = casefold

-- Split text into word/number tokens using luautf8's Unicode-aware Lua patterns,
-- so punctuation/whitespace of ANY script are separators - no hand-listed table
-- A digit run is split from an adjacent letter run so "600mm" -> {"600","mm"}
-- Off-device/test only (see header); requires luautf8, resolved lazily
local lutf8_tok
function M.tokenize(s)
	if not lutf8_tok then
		local ok, m = pcall(require, "lua-utf8")

		if not (ok and m and m.gsub) then
			error(
				"unitlens/util.tokenize needs luautf8 (off-device helper only). "
					.. "On device, feed crengine word tokens to matcher.match instead."
			)
		end
		lutf8_tok = m
	end

	local u = lutf8_tok

	s = u.gsub(s, "[^%a%d]+", " ") -- any-script punctuation/space -> one space
	s = u.gsub(s, "(%a)(%d)", "%1 %2") -- split letter|digit boundary
	s = u.gsub(s, "(%d)(%a)", "%1 %2") -- split digit|letter boundary

	local tokens = {}

	for tok in s:gmatch("%S+") do
		tokens[#tokens + 1] = tok
	end

	return tokens
end

function M.is_number(tok)
	return tok:match("^%d+$") ~= nil
end

return M
