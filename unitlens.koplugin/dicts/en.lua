--[[
dicts/en.lua - English dictionary (length).

Format: see docs/spec.md §4. Values are precomputed strings (docs/units.md).
Customary/imperial units convert -> metric; metric units convert -> customary.

Only single-word forms are listed: the matcher tests one token at a time, so
multi-word units (square metre, miles per hour) are out of scope. The nautical
mile is folded into `mile` as an extra result (nmi/NM symbols land there too) —
the reader picks the land/sea value from context.
]]

return {
	lang = "en",
	name = "English",

	strings = {
		system_label = "System",
		category_label = "Category",
		systems = { customary = "Customary", metric = "Metric" },
		categories = { length = "Length" },
	},

	units = {

		-- ── Length ────────────────────────────────────────────────────────
		league = {
			name = "league",
			system = "customary",
			category = "length",
			forms = { "league", "leagues" },
			symbols = { "lea" },
			results = { { value = "4.828", unit = "km" } },
		},
		mile = {
			name = "mile",
			system = "customary",
			category = "length",
			forms = { "mile", "miles" },
			symbols = { "mi", "nmi", "NM" },
			results = {
				{ value = "1.609", unit = "km", label = "statute" },
				{ value = "1.852", unit = "km", label = "nautical" },
			},
		},
		furlong = {
			name = "furlong",
			system = "customary",
			category = "length",
			forms = { "furlong", "furlongs" },
			symbols = { "fur" },
			results = { { value = "201.17", unit = "m" } },
		},
		chain = {
			name = "chain",
			system = "customary",
			category = "length",
			forms = { "chain", "chains" },
			symbols = { "ch" },
			results = { { value = "20.117", unit = "m" } },
		},
		yard = {
			name = "yard",
			system = "customary",
			category = "length",
			forms = { "yard", "yards" },
			symbols = { "yd" },
			results = { { value = "0.9144", unit = "m" } },
		},
		foot = {
			name = "foot",
			system = "customary",
			category = "length",
			forms = { "foot", "feet" },
			symbols = { "ft", "′" },
			results = { { value = "0.3048", unit = "m" } },
		},
		inch = {
			name = "inch",
			system = "customary",
			category = "length",
			forms = { "inch", "inches" },
			symbols = { "in", "″" },
			results = { { value = "2.54", unit = "cm" } },
		},
		kilometre = {
			name = "kilometre",
			system = "metric",
			category = "length",
			symbols = { "km" },
			forms = { "kilometre", "kilometres", "kilometer", "kilometers" },
			results = { { value = "0.6214", unit = "mi" } },
		},
		hectometre = {
			name = "hectometre",
			system = "metric",
			category = "length",
			symbols = { "hm" },
			forms = { "hectometre", "hectometres", "hectometer", "hectometers" },
			results = {
				{ value = "100", unit = "m" },
				{ value = "328.08", unit = "ft" },
			},
		},
		decametre = {
			name = "decametre",
			system = "metric",
			category = "length",
			symbols = { "dam" },
			forms = {
				"decametre",
				"decametres",
				"decameter",
				"decameters",
				"dekametre",
				"dekametres",
				"dekameter",
				"dekameters",
			},
			results = {
				{ value = "10", unit = "m" },
				{ value = "32.81", unit = "ft" },
			},
		},
		metre = {
			name = "metre",
			system = "metric",
			category = "length",
			symbols = { "m" },
			forms = { "metre", "metres", "meter", "meters" },
			results = { { value = "3.28084", unit = "ft" } },
		},
		decimetre = {
			name = "decimetre",
			system = "metric",
			category = "length",
			symbols = { "dm" },
			forms = { "decimetre", "decimetres", "decimeter", "decimeters" },
			results = { { value = "3.937", unit = "in" } },
		},
		centimetre = {
			name = "centimetre",
			system = "metric",
			category = "length",
			symbols = { "cm" },
			forms = { "centimetre", "centimetres", "centimeter", "centimeters" },
			results = { { value = "0.3937", unit = "in" } },
		},
		millimetre = {
			name = "millimetre",
			system = "metric",
			category = "length",
			symbols = { "mm" },
			forms = { "millimetre", "millimetres", "millimeter", "millimeters" },
			results = { { value = "0.03937", unit = "in" } },
		},
		micrometre = {
			name = "micrometre",
			system = "metric",
			category = "length",
			symbols = { "µm", "um" },
			forms = {
				"micrometre",
				"micrometres",
				"micrometer",
				"micrometers",
				"micron",
				"microns",
			},
			results = {
				{ value = "0.001", unit = "mm" },
				{ value = "1000", unit = "nm" },
			},
		},
		nanometre = {
			name = "nanometre",
			system = "metric",
			category = "length",
			symbols = { "nm" },
			forms = { "nanometre", "nanometres", "nanometer", "nanometers" },
			results = {
				{ value = "0.001", unit = "µm" },
				{ value = "0.000001", unit = "mm" },
			},
		},
	},
}
