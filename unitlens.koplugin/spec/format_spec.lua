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

	-- Graceful skip: arshin has no `system`, so that header line is omitted;
	-- two results -> two lines.
	t.eq(
		format.popup(ru.units.arshin, ru.strings),
		"Категория: Длина\n\n1 аршин = 71,12 см\n1 аршин = 0,7112 м",
		"ru arshin popup (skipped system + multi-result)"
	)

	-- No strings at all -> only the result line(s), no header, no blank line.
	t.eq(format.popup(en.units.mile, {}), "1 mile = 1.609 km", "popup with empty strings skips header")

	-- Simple mode (detailed = false): conversion only, header dropped even when
	-- strings are present. Multi-result still lists every line.
	t.eq(format.popup(en.units.foot, en.strings, false), "1 foot = 0.3048 m", "en foot simple popup")
	t.eq(
		format.popup(ru.units.arshin, ru.strings, false),
		"1 аршин = 71,12 см\n1 аршин = 0,7112 м",
		"ru arshin simple popup (multi-result, no header)"
	)
end
