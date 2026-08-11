return function(t)
	local dict = require("ul_dict")
	local matcher = require("ul_matcher")
	local en = dict.compile(require("dicts.en"))
	local ru = dict.compile(require("dicts.ru"))

	-- Collect matched unit keys in order.
	local function keys(text, d)
		local r = {}
		for _, m in ipairs(matcher.match_text(d, text)) do
			r[#r + 1] = m.unit.key
		end
		return r
	end

	-- Spelled-number sentence: the unit WORD lights up, no number parsed (§3.2).
	t.eq(keys("Это было в двенадцати футах от забора.", ru), { "foot" }, "ru: футах standalone")

	-- English full words match standalone too.
	t.eq(keys("he walked several miles", en), { "mile" }, "en: miles standalone")

	-- Symbol with an adjacent digit matches; the classic 600 mm case.
	t.eq(keys("about 600 mm wide", en), { "millimetre" }, "en: 600 mm -> millimetre")
	t.eq(keys("6 ft tall", en), { "foot" }, "en: 6 ft -> foot")
	t.eq(keys("600mm", en), { "millimetre" }, "en: glued 600mm -> millimetre")

	-- Bare symbol with NO adjacent digit must NOT match (the whole point).
	t.eq(keys("stopped in the doorway", en), {}, "en: bare 'in' ignored")
	t.eq(keys("the room was m wide", en), {}, "en: bare 'm' ignored")

	-- Exact-token membership: substrings never match.
	t.eq(keys("играли в футбол", ru), {}, "ru: футбол is not фут")

	-- Multiple units on one line, in order.
	t.eq(keys("6 ft and 3 inches", en), { "foot", "inch" }, "en: two matches in order")
end
