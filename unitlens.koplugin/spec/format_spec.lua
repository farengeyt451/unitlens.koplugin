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

	-- Volume: gallon folds US + UK into one word (labelled results).
	t.eq(
		format.popup(ru.units.gallon, ru.strings),
		"Система: Имперская\nКатегория: Объём\n\n1 галлон = 3,785 л - амер.\n1 галлон = 4,546 л - брит.",
		"ru gallon popup (US/UK variants)"
	)

	-- Volume: uncommon metric unit leads with a familiar-scale result.
	t.eq(
		format.popup(en.units.hectolitre, en.strings),
		"System: Metric\nCategory: Volume\n\n1 hectolitre = 100 L\n1 hectolitre = 26.42 gal - US\n1 hectolitre = 22 gal - UK",
		"en hectolitre popup (familiar-scale + US/UK)"
	)

	-- Cross-category fold: "ounce" has no system/category -> header-less popup with
	-- the weight ounce plus both fluid ounces.
	t.eq(
		format.popup(ru.units.ounce, ru.strings),
		"1 унция = 28,35 г - вес\n1 унция = 29,57 мл - жидк. (амер.)\n1 унция = 28,41 мл - жидк. (брит.)",
		"ru ounce popup (weight + fluid, header-less)"
	)

	-- Area: acre -> metric with hectare + m² results.
	t.eq(
		format.popup(ru.units.acre, ru.strings),
		"Система: Имперская\nКатегория: Площадь\n\n1 акр = 0,405 га\n1 акр = 4047 м²",
		"ru acre popup (area, ha + m²)"
	)

	-- Temperature: affine -> results are formula strings (r.text), no "1 name =".
	t.eq(
		format.popup(ru.units.celsius, ru.strings),
		"Система: Метрическая\nКатегория: Температура\n\n°F = °C × 9/5 + 32\nK = °C + 273,15\nПрикидка: °F ≈ 2 × °C + 30",
		"ru celsius popup (formulas + rule of thumb)"
	)
	t.eq(
		format.popup(en.units.fahrenheit, en.strings, false),
		"°C = (°F − 32) × 5/9\nK = (°F − 32) × 5/9 + 273.15\nRule of thumb: °C ≈ (°F − 30) / 2",
		"en fahrenheit simple popup (formulas + rule of thumb)"
	)
end
