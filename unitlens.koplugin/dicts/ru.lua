--[[
dicts/ru.lua — Russian dictionary (length subset for Milestone 1).

Format: see docs/spec.md §4. Values are precomputed strings with a comma decimal
mark (docs/units.md). Imperial units rarely carry symbols in Russian prose, so
only the metric side declares digit-gated symbols (м, см, мм, км).
]]

return {
	lang = "ru",
	name = "Русский",

	strings = {
		system_label = "Система",
		category_label = "Категория",
		systems = { customary = "Американская/Британская", metric = "Метрическая" },
		categories = { length = "Длина" },
	},

	units = {

		-- Customary -> metric
		inch = {
			name = "дюйм",
			system = "customary",
			category = "length",
			forms = { "дюйм", "дюйма", "дюйму", "дюймом", "дюйме", "дюймы", "дюймов", "дюймам", "дюймами", "дюймах" },
			results = { { value = "2,54", unit = "см" } },
		},
		foot = {
			name = "фут",
			system = "customary",
			category = "length",
			forms = { "фут", "фута", "футу", "футом", "футе", "футы", "футов", "футам", "футами", "футах" },
			results = { { value = "0,3048", unit = "м" } },
		},
		yard = {
			name = "ярд",
			system = "customary",
			category = "length",
			forms = { "ярд", "ярда", "ярду", "ярдом", "ярде", "ярды", "ярдов", "ярдам", "ярдами", "ярдах" },
			results = { { value = "0,9144", unit = "м" } },
		},
		mile = {
			name = "миля",
			system = "customary",
			category = "length",
			forms = { "миля", "мили", "миле", "милю", "милей", "милею", "миль", "милям", "милями", "милях" },
			results = { { value = "1,609", unit = "км" } },
		},

		-- Metric -> customary
		millimetre = {
			name = "мм",
			system = "metric",
			category = "length",
			forms = { "миллиметр", "миллиметра", "миллиметру", "миллиметром", "миллиметре", "миллиметры", "миллиметров", "миллиметрам", "миллиметрами", "миллиметрах" },
			symbols = { "мм" },
			results = { { value = "0,03937", unit = "дюйма" } },
		},
		centimetre = {
			name = "см",
			system = "metric",
			category = "length",
			forms = { "сантиметр", "сантиметра", "сантиметру", "сантиметром", "сантиметре", "сантиметры", "сантиметров", "сантиметрам", "сантиметрами", "сантиметрах" },
			symbols = { "см" },
			results = { { value = "0,3937", unit = "дюйма" } },
		},
		metre = {
			name = "метр",
			system = "metric",
			category = "length",
			forms = { "метр", "метра", "метру", "метром", "метре", "метры", "метров", "метрам", "метрами", "метрах" },
			symbols = { "м" },
			results = { { value = "3,28084", unit = "фута" } },
		},
		kilometre = {
			name = "км",
			system = "metric",
			category = "length",
			forms = { "километр", "километра", "километру", "километром", "километре", "километры", "километров", "километрам", "километрами", "километрах" },
			symbols = { "км" },
			results = { { value = "0,6214", unit = "мили" } },
		},

		-- Historical unit with no `system` and no `symbols` (exercises graceful
		-- skip + a multi-result popup). Matches the spec §4 example.
		arshin = {
			name = "аршин",
			category = "length",
			forms = { "аршин", "аршина", "аршину", "аршином", "аршине", "аршины", "аршинам", "аршинами", "аршинах" },
			results = {
				{ value = "71,12", unit = "см" },
				{ value = "0,7112", unit = "м" },
			},
		},
	},
}
