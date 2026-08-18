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

	-- M7: Russian mass/volume spelled forms match standalone.
	t.eq(keys("он весил три фунта", ru), { "pound" }, "ru: фунта -> pound")
	t.eq(keys("бочка на сто галлонов", ru), { "gallon" }, "ru: галлонов -> gallon")
	t.eq(keys("в двух унциях золота", ru), { "ounce" }, "ru: унциях -> ounce")
	t.eq(keys("выпил пинту эля", ru), { "pint" }, "ru: пинту -> pint")

	-- M7: Russian metric symbols are digit-gated.
	t.eq(keys("масса 5 кг", ru), { "kilogram" }, "ru: 5 кг -> kilogram")
	t.eq(keys("добавьте 200 г муки", ru), { "gram" }, "ru: 200 г -> gram")
	t.eq(keys("бутыль на 3 л", ru), { "litre" }, "ru: 3 л -> litre")
	t.eq(keys("вес т неизвестен", ru), {}, "ru: bare т (no digit) ignored")

	-- M7 length: new Russian units (spelled forms + digit-gated metric symbols).
	t.eq(keys("отшагал десять лиг", ru), { "league" }, "ru: лиг -> league")
	t.eq(keys("до цели один фурлонг", ru), { "furlong" }, "ru: фурлонг -> furlong")
	t.eq(keys("толщина 5 мкм", ru), { "micrometre" }, "ru: 5 мкм -> micrometre")
	t.eq(keys("волна 500 нм", ru), { "nanometre" }, "ru: 500 нм -> nanometre")

	-- M7 length: new English units + micron alias; the nautical-mile symbol nmi
	-- now folds into `mile` (both land/sea results shown in the popup).
	t.eq(keys("a hectometre track", en), { "hectometre" }, "en: hectometre standalone")
	t.eq(keys("about 40 microns", en), { "micrometre" }, "en: microns -> micrometre")
	t.eq(keys("10 nmi offshore", en), { "mile" }, "en: 10 nmi -> mile (nautical result)")
end
