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

	-- Mass: Russian spelled forms match standalone; ton/hundredweight fold to one
	-- word with several labelled results (see format_spec).
	t.eq(keys("он весил три фунта", ru), { "pound" }, "ru: фунта -> pound")
	t.eq(keys("в двух унциях золота", ru), { "ounce" }, "ru: унциях -> ounce")
	t.eq(keys("груз весом в тонну", ru), { "tonne" }, "ru: тонну -> tonne")
	t.eq(keys("собрали сто центнеров", ru), { "quintal" }, "ru: центнеров -> quintal")
	t.eq(keys("весил десять стоунов", ru), { "stone" }, "ru: стоунов -> stone")

	-- Mass: Russian metric symbols are digit-gated.
	t.eq(keys("масса 5 кг", ru), { "kilogram" }, "ru: 5 кг -> kilogram")
	t.eq(keys("добавьте 200 г муки", ru), { "gram" }, "ru: 200 г -> gram")
	t.eq(keys("груз 2 т", ru), { "tonne" }, "ru: 2 т -> tonne")
	t.eq(keys("доза 50 мкг", ru), { "microgram" }, "ru: 50 мкг -> microgram")
	t.eq(keys("вес т неизвестен", ru), {}, "ru: bare т (no digit) ignored")

	-- Mass: English forms + digit-gated symbols; the ton word covers metric/long/short.
	t.eq(keys("weighed ten pounds", en), { "pound" }, "en: pounds -> pound")
	t.eq(keys("just a few ounces", en), { "ounce" }, "en: ounces -> ounce")
	t.eq(keys("hauled three tons", en), { "tonne" }, "en: tons -> tonne")
	t.eq(keys("about 10 cwt", en), { "hundredweight" }, "en: 10 cwt -> hundredweight")
	t.eq(keys("twelve stone heavy", en), { "stone" }, "en: stone standalone (no symbol)")
	-- Stone has no symbol on purpose, so ordinals like "21st" do NOT false-match.
	t.eq(keys("finished 21st", en), {}, "en: 21st is not stone")

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

	-- Volume: Russian spelled forms; gallon/quart/pint fold US+UK into one word.
	t.eq(keys("выпил галлон воды", ru), { "gallon" }, "ru: галлон -> gallon")
	t.eq(keys("две кварты молока", ru), { "quart" }, "ru: кварты -> quart")
	t.eq(keys("бочка нефти баррель", ru), { "barrel" }, "ru: баррель -> barrel")
	t.eq(keys("объём 3 л", ru), { "litre" }, "ru: 3 л -> litre")
	t.eq(keys("добавь 50 мл", ru), { "millilitre" }, "ru: 50 мл -> millilitre")

	-- Volume: English forms + digit-gated symbols.
	t.eq(keys("a pint of ale", en), { "pint" }, "en: pint -> pint")
	t.eq(keys("50 gal drum", en), { "gallon" }, "en: 50 gal -> gallon")
	t.eq(keys("about 2 L", en), { "litre" }, "en: 2 L -> litre")

	-- Area: Russian spelled forms (incl. сотка) + digit-gated га.
	t.eq(keys("поле в десять гектаров", ru), { "hectare" }, "ru: гектаров -> hectare")
	t.eq(keys("участок шесть соток", ru), { "are" }, "ru: соток -> are (сотка)")
	t.eq(keys("купил три акра земли", ru), { "acre" }, "ru: акра -> acre")
	t.eq(keys("площадь 5 га", ru), { "hectare" }, "ru: 5 га -> hectare")

	-- Area: English hectare/acre; the are (verb!) is deliberately NOT shipped.
	t.eq(keys("a hectare of land", en), { "hectare" }, "en: hectare -> hectare")
	t.eq(keys("fifty acres of wheat", en), { "acre" }, "en: acres -> acre")
	t.eq(keys("we are here now", en), {}, "en: verb 'are' is not a unit")

	-- Temperature: spelled forms match; Kelvin's bare K is digit-gated. (Popup is
	-- a formula, not a 1:1 value — see format_spec.)
	t.eq(keys("измерено по шкале Цельсия", ru), { "celsius" }, "ru: Цельсия -> celsius")
	t.eq(keys("температура по Фаренгейту", ru), { "fahrenheit" }, "ru: Фаренгейту -> fahrenheit")
	t.eq(keys("около трёхсот кельвинов", ru), { "kelvin" }, "ru: кельвинов -> kelvin")
	t.eq(keys("measured in fahrenheit", en), { "fahrenheit" }, "en: fahrenheit -> fahrenheit")
	t.eq(keys("the core hit 300 K", en), { "kelvin" }, "en: 300 K -> kelvin")

	-- Fathom: English word + symbol; Russian matches the transliteration "фатом".
	t.eq(keys("five fathoms deep", en), { "fathom" }, "en: fathoms -> fathom")
	t.eq(keys("на глубине десяти фатомов", ru), { "fathom" }, "ru: фатомов -> fathom")

	-- Russian historical units (старорусские меры) match by spelled form.
	t.eq(keys("три версты до села", ru), { "versta" }, "ru: версты -> versta")
	t.eq(keys("от горшка два вершка", ru), { "vershok" }, "ru: вершка -> vershok")
	t.eq(keys("косая сажень в плечах", ru), { "sazhen" }, "ru: сажень -> sazhen")
	t.eq(keys("ростом два аршина", ru), { "arshin" }, "ru: аршина -> arshin")
	t.eq(keys("привёз пять пудов муки", ru), { "pud" }, "ru: пудов -> pud")
	t.eq(keys("золотник серебра", ru), { "zolotnik" }, "ru: золотник -> zolotnik")
	t.eq(keys("десятина пахотной земли", ru), { "desyatina" }, "ru: десятина -> desyatina")

	-- "фунт" now folds English + Russian pound into one match.
	t.eq(keys("он весил три фунта", ru), { "pound" }, "ru: фунта -> pound (folded)")
end
