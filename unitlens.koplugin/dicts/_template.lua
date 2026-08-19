--[[
dicts/_template.lua - copy this to dicts/<code>.lua to add a Book language.

Files starting with "_" are skipped by auto-discovery, so this template never
shows up as a language. Copy it, rename it to a BCP-47 primary subtag (de.lua,
fr.lua, uk.lua, …), set `lang` and `name`, and fill in `units`.

Model (see docs/dictionaries.md and docs/spec.md §4):
  * Nothing is computed at runtime. Every answer is a precomputed STRING you write
    here, taken from docs/units.md. Use your language's decimal mark (0.3048 vs 0,3048).
  * A unit matches by `forms` (spelled words, matched ANYWHERE) or by `symbols`
    (abbreviations, matched ONLY next to a digit - "6 ft", "40 m").
  * The popup is assembled from `name`, `results`, and the localized `strings`.
]]

return {
	-- BCP-47 primary subtag / ISO 639-1 code. Must equal the file name.
	lang = "xx",

	-- Endonym shown in Tools ▸ Unit Lens ▸ Book language (the language in itself,
	-- e.g. "Deutsch", "Français", "Українська").
	name = "Language name",

	-- Localized popup chrome. Each unit's `system`/`category` is looked up here;
	-- if a key is missing, that header line is simply skipped (no crash).
	strings = {
		system_label = "System",
		category_label = "Category",
		systems = {
			metric = "Metric",
			customary = "Imperial",
			-- add your own, e.g. russian = "Русская"
		},
		categories = {
			length = "Length",
			mass = "Mass",
			volume = "Volume",
			area = "Area",
			temperature = "Temperature",
		},
	},

	units = {
		-- 1) Simplest unit: full spelled forms + a digit-gated symbol, one result.
		--    Detailed popup:
		--        System: Imperial
		--        Category: Length
		--        1 foot = 0.3048 m
		foot = {
			name = "foot", -- what prints after "1 " in the popup
			system = "customary", -- -> strings.systems.customary (optional)
			category = "length", -- -> strings.categories.length (optional)
			forms = { "foot", "feet" }, -- match ANYWHERE (list every inflected form)
			symbols = { "ft" }, -- match ONLY beside a number ("6 ft")
			results = { { value = "0.3048", unit = "m" } },
		},

		-- 2) One word, several answers: fold variants into labelled results and let
		--    the reader pick by context. The popup lists every line.
		--        1 mile = 1.609 km - statute
		--        1 mile = 1.852 km - nautical
		mile = {
			name = "mile",
			system = "customary",
			category = "length",
			forms = { "mile", "miles" },
			symbols = { "mi" },
			results = {
				{ value = "1.609", unit = "km", label = "statute" },
				{ value = "1.852", unit = "km", label = "nautical" },
			},
		},

		-- 3) Metric unit: its symbol is digit-gated too, so a bare "m" in prose
		--    never matches - only "40 m" does.
		metre = {
			name = "metre",
			system = "metric",
			category = "length",
			forms = { "metre", "metres", "meter", "meters" },
			symbols = { "m" },
			results = { { value = "3.281", unit = "ft" } },
		},

		-- 4) Cross-system fold: omit `system` (and/or `category`) to drop that
		--    header line, e.g. a word that means two things in two systems.
		--        Category: Mass
		--        1 pound = 453.6 g - avoirdupois
		--        1 pound = 373.2 g - troy
		pound = {
			name = "pound",
			category = "mass", -- no `system`: the header omits the System line
			forms = { "pound", "pounds" },
			symbols = { "lb", "lbs" },
			results = {
				{ value = "453.6", unit = "g", label = "avoirdupois" },
				{ value = "373.2", unit = "g", label = "troy" },
			},
		},

		-- 5) Ambiguous word that is ALSO common prose: keep it OUT of `forms` and
		--    put the spelled word in `symbols`, so it only lights up beside a digit.
		--    (Inclusion is the filter - see README "False positives".)
		-- bar = {
		--     name = "bar", system = "metric", category = "pressure",
		--     symbols = { "bar" }, -- digit-gated: "2 bar", never the noun "bar"
		--     results = { { value = "0.987", unit = "atm" } },
		-- },

		-- 6) Temperature is affine (no single factor). Use raw `text` result lines
		--    instead of value/unit; they print verbatim, with no "1 name =" prefix.
		--        °F = °C × 9/5 + 32
		--        K = °C + 273.15
		celsius = {
			name = "celsius",
			system = "metric",
			category = "temperature",
			forms = { "celsius", "centigrade" },
			symbols = { "°C" },
			results = {
				{ text = "°F = °C × 9/5 + 32" },
				{ text = "K = °C + 273.15" },
			},
		},
	},
}
