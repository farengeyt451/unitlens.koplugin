return function(t)
	local dict = require("ul_dict")
	local format = require("ul_format")
	local en = dict.compile(require("dicts.en"))
	local ru = dict.compile(require("dicts.ru"))

	-- Single result with full header (en).
	t.eq(
		format.popup(en.units.foot, en.strings),
		"System: Customary\nCategory: Length\n\n1 foot = 0.3048 m",
		"en foot popup"
	)

	-- Single result, Russian header + comma decimal.
	t.eq(
		format.popup(ru.units.metre, ru.strings),
		"Система: Метрическая\nКатегория: Длина\n\n1 метр = 3,28084 фута",
		"ru metre popup"
	)

	-- Graceful skip: тонна has no `system`, so that header line is omitted;
	-- three folded results -> three lines.
	t.eq(
		format.popup(ru.units.tonne, ru.strings),
		"Категория: Масса\n\n1 тонна = 1000 кг - метрическая\n1 тонна = 1016 кг - длинная (брит.)\n1 тонна = 907 кг - короткая (амер.)",
		"ru tonne popup (skipped system + folded variants)"
	)

	-- No strings at all -> only the result line(s), no header, no blank line.
	t.eq(
		format.popup(en.units.mile, {}),
		"1 mile = 1.609 km - statute\n1 mile = 1.852 km - nautical",
		"popup with empty strings skips header"
	)

	-- Simple mode (detailed = false): conversion only, header dropped even when
	-- strings are present. Multi-result still lists every line.
	t.eq(format.popup(en.units.foot, en.strings, false), "1 foot = 0.3048 m", "en foot simple popup")
	t.eq(
		format.popup(ru.units.tonne, ru.strings, false),
		"1 тонна = 1000 кг - метрическая\n1 тонна = 1016 кг - длинная (брит.)\n1 тонна = 907 кг - короткая (амер.)",
		"ru tonne simple popup (multi-result, no header)"
	)

	-- M7: mass unit with the new category header.
	t.eq(
		format.popup(ru.units.pound, ru.strings),
		"Система: Имперская\nКатегория: Масса\n\n1 фунт = 453,6 г",
		"ru pound popup (mass)"
	)

	-- Mass unit with long/short variants -> labelled result lines.
	t.eq(
		format.popup(ru.units.hundredweight, ru.strings),
		"Система: Имперская\nКатегория: Масса\n\n1 хандредвейт = 50,8 кг - длинный (брит.)\n1 хандредвейт = 45,36 кг - короткий (амер.)",
		"ru hundredweight popup (long/short labels)"
	)
	t.eq(
		format.popup(ru.units.hundredweight, ru.strings, false),
		"1 хандредвейт = 50,8 кг - длинный (брит.)\n1 хандредвейт = 45,36 кг - короткий (амер.)",
		"ru hundredweight simple popup"
	)

	-- M7 length: uncommon metric unit leads with a familiar-scale result.
	t.eq(
		format.popup(en.units.hectometre, en.strings),
		"System: Metric\nCategory: Length\n\n1 hectometre = 100 m\n1 hectometre = 328.08 ft",
		"en hectometre popup (familiar-scale + imperial)"
	)

	-- One word "миля" -> land + sea shown as two labelled results.
	t.eq(
		format.popup(ru.units.mile, ru.strings),
		"Система: Имперская\nКатегория: Длина\n\n1 миля = 1,609 км - сухопутная\n1 миля = 1,852 км - морская",
		"ru mile popup (land + sea variants)"
	)
end
