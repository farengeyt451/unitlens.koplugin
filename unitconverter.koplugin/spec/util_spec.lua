return function(t)
	local util = require("util")

	-- casefold: full Unicode via utf8proc/luautf8 (no hand-rolled case table)
	t.eq(util.casefold("Miles"), "miles", "casefold latin")
	t.eq(util.casefold("ФУТАХ"), "футах", "casefold cyrillic upper")
	t.eq(util.casefold("Ёлка"), "ёлка", "casefold Ё -> ё")
	t.eq(util.casefold("футах"), "футах", "casefold idempotent")
	-- Scripts the old ASCII+Russian table could NOT handle:
	t.eq(util.casefold("ҐАНОК"), "ґанок", "casefold Ukrainian Ґ")
	t.eq(util.casefold("MÈTRES"), "mètres", "casefold accented Latin")

	-- tokenize: whitespace/punctuation dropped, digit runs split from letters
	t.eq(util.tokenize("600 mm"), { "600", "mm" }, "tokenize spaced number+unit")
	t.eq(util.tokenize("600mm"), { "600", "mm" }, "tokenize glued number+unit")
	t.eq(util.tokenize("в двенадцати футах"), { "в", "двенадцати", "футах" }, "tokenize cyrillic sentence")
	t.eq(util.tokenize("stopped in the doorway."), { "stopped", "in", "the", "doorway" }, "tokenize drops period")
	t.eq(util.tokenize("«6 футов»"), { "6", "футов" }, "tokenize drops guillemets")
	-- any-script punctuation is a separator now (was missed by the old hand-list)
	t.eq(util.tokenize("6フィート。"), { "6", "フィート" }, "tokenize splits CJK full stop")
	t.eq(util.tokenize("5\226\128\145km"), { "5", "km" }, "tokenize splits non-breaking hyphen U+2011")

	-- is_number
	t.truthy(util.is_number("600"), "600 is a number")
	t.truthy(not util.is_number("mm"), "mm is not a number")
	t.truthy(not util.is_number("6ft"), "6ft is not a pure number (already split anyway)")
end
