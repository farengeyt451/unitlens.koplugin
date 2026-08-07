--[[
util.lua — pure text helpers (no KOReader UI dependency).

Unicode work is delegated to full-Unicode libraries so any language works with
zero hand-maintained tables (no case tables, no punctuation lists):
  * inside KOReader  -> ffi/utf8proc  (bundled with KOReader) — case-folding
  * off-device tests -> luautf8       (`luarocks install --local luautf8`)

Environment split:
  * `casefold` runs in BOTH environments (utf8proc on device, luautf8 in tests).
  * `tokenize` is an off-device / test helper only. On device the scanner feeds
    crengine's Unicode-aware word tokens straight to matcher.match, so tokenize
    is never on the device path — it may therefore lean on luautf8's patterns.
Everything is unit-testable off-device with lua5.1 / luajit.
]]

local M = {}

-- Resolve a full-Unicode lowercaser exactly once, at load time. There is NO
-- silent ASCII fallback: if neither library is present we fail loudly rather
-- than mis-match non-Latin text.
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
				"unitconverter/util: no Unicode lowercaser found — expected KOReader's "
					.. "'ffi/utf8proc' on device, or luautf8 for off-device tests "
					.. "(`luarocks install --local luautf8`)."
			)
		end
	end
end

-- Case-fold a string for matching (full Unicode via the resolved library).
M.casefold = casefold

-- Split text into word/number tokens using luautf8's Unicode-aware Lua patterns,
-- so punctuation/whitespace of ANY script are separators — no hand-listed table.
-- A digit run is split from an adjacent letter run so "600mm" -> {"600","mm"}.
-- Off-device/test only (see header); requires luautf8, resolved lazily.
local lutf8_tok
function M.tokenize(s)
	if not lutf8_tok then
		local ok, m = pcall(require, "lua-utf8")
		if not (ok and m and m.gsub) then
			error(
				"unitconverter/util.tokenize needs luautf8 (off-device helper only). "
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

-- A "number token" is a pure run of ASCII digits. Kept ASCII on purpose: this
-- runs on device inside matcher.match, where only utf8proc is available (no
-- digit classification), and ru/en books use ASCII digits 0-9. Non-ASCII digit
-- systems (e.g. Arabic-Indic ٦) are a known limitation for future languages.
function M.is_number(tok)
	return tok:match("^%d+$") ~= nil
end

return M
