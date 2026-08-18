--[[
dicts/en.lua - English dictionary (length, mass, volume).

Format: see docs/spec.md §4. Values are precomputed strings (docs/units.md).
Customary/imperial units convert -> metric; metric units convert -> customary.

Single-word only (the matcher tests one token at a time); multi-word units are out
of scope. Units that share one word across systems are folded into a single entry
with several labelled results, so the reader picks by context: mile (statute/
nautical), ton (metric/long/short), hundredweight (long/short), gallon/quart/pint
(US/UK), ounce (weight + fluid US/UK, cross-category so header-less).
]]

return {
	lang = "en",
	name = "English",

	strings = {
		system_label = "System",
		category_label = "Category",
		systems = { customary = "Customary", metric = "Metric" },
		categories = { length = "Length", mass = "Mass", volume = "Volume" },
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

		-- ── Mass / weight ─────────────────────────────────────────────────
		tonne = {
			name = "ton",
			category = "mass",
			symbols = { "t" },
			forms = { "tonne", "tonnes", "ton", "tons" },
			results = {
				{ value = "1000", unit = "kg", label = "metric" },
				{ value = "1016", unit = "kg", label = "long (UK)" },
				{ value = "907", unit = "kg", label = "short (US)" },
			},
		},
		quintal = {
			name = "quintal",
			system = "metric",
			category = "mass",
			symbols = { "q" },
			forms = { "quintal", "quintals" },
			results = {
				{ value = "100", unit = "kg" },
				{ value = "220.5", unit = "lb" },
			},
		},
		kilogram = {
			name = "kilogram",
			system = "metric",
			category = "mass",
			symbols = { "kg" },
			forms = { "kilogram", "kilograms", "kilogramme", "kilogrammes" },
			results = { { value = "2.205", unit = "lb" } },
		},
		gram = {
			name = "gram",
			system = "metric",
			category = "mass",
			symbols = { "g" },
			forms = { "gram", "grams", "gramme", "grammes" },
			results = { { value = "0.0353", unit = "oz" } },
		},
		milligram = {
			name = "milligram",
			system = "metric",
			category = "mass",
			symbols = { "mg" },
			forms = { "milligram", "milligrams", "milligramme", "milligrammes" },
			results = {
				{ value = "0.001", unit = "g" },
				{ value = "0.0154", unit = "gr" },
			},
		},
		microgram = {
			name = "microgram",
			system = "metric",
			category = "mass",
			symbols = { "µg", "mcg", "ug" },
			forms = { "microgram", "micrograms", "microgramme", "microgrammes" },
			results = {
				{ value = "0.001", unit = "mg" },
				{ value = "0.000001", unit = "g" },
			},
		},
		hundredweight = {
			name = "hundredweight",
			system = "customary",
			category = "mass",
			symbols = { "cwt" },
			forms = { "hundredweight", "hundredweights" },
			results = {
				{ value = "50.8", unit = "kg", label = "long (UK)" },
				{ value = "45.36", unit = "kg", label = "short (US)" },
			},
		},
		stone = {
			name = "stone",
			system = "customary",
			category = "mass",
			forms = { "stone", "stones" },
			results = { { value = "6.35", unit = "kg" } },
		},
		pound = {
			name = "pound",
			system = "customary",
			category = "mass",
			symbols = { "lb", "lbs" },
			forms = { "pound", "pounds" },
			results = { { value = "453.6", unit = "g" } },
		},
		ounce = {
			name = "ounce",
			symbols = { "oz" },
			forms = { "ounce", "ounces" },
			results = {
				{ value = "28.35", unit = "g", label = "weight" },
				{ value = "29.57", unit = "mL", label = "fluid US" },
				{ value = "28.41", unit = "mL", label = "fluid UK" },
			},
		},
		dram = {
			name = "dram",
			system = "customary",
			category = "mass",
			symbols = { "dr" },
			forms = { "dram", "drams", "drachm", "drachms" },
			results = { { value = "3.888", unit = "g", label = "apothecary" } },
		},
		grain = {
			name = "grain",
			system = "customary",
			category = "mass",
			symbols = { "gr" },
			forms = { "grain", "grains" },
			results = { { value = "64.8", unit = "mg" } },
		},

		-- ── Volume ────────────────────────────────────────────────────────
		hectolitre = {
			name = "hectolitre",
			system = "metric",
			category = "volume",
			symbols = { "hl" },
			forms = { "hectolitre", "hectolitres", "hectoliter", "hectoliters" },
			results = {
				{ value = "100", unit = "L" },
				{ value = "26.42", unit = "gal", label = "US" },
				{ value = "22", unit = "gal", label = "UK" },
			},
		},
		litre = {
			name = "litre",
			system = "metric",
			category = "volume",
			symbols = { "L", "l" },
			forms = { "litre", "litres", "liter", "liters" },
			results = {
				{ value = "2.11", unit = "pt", label = "US" },
				{ value = "1.76", unit = "pt", label = "UK" },
			},
		},
		decilitre = {
			name = "decilitre",
			system = "metric",
			category = "volume",
			symbols = { "dl" },
			forms = { "decilitre", "decilitres", "deciliter", "deciliters" },
			results = {
				{ value = "100", unit = "mL" },
				{ value = "3.38", unit = "fl oz", label = "US" },
				{ value = "3.52", unit = "fl oz", label = "UK" },
			},
		},
		millilitre = {
			name = "millilitre",
			system = "metric",
			category = "volume",
			symbols = { "mL", "ml" },
			forms = { "millilitre", "millilitres", "milliliter", "milliliters" },
			results = {
				{ value = "0.0338", unit = "fl oz", label = "US" },
				{ value = "0.0352", unit = "fl oz", label = "UK" },
			},
		},
		gallon = {
			name = "gallon",
			system = "customary",
			category = "volume",
			symbols = { "gal" },
			forms = { "gallon", "gallons" },
			results = {
				{ value = "3.785", unit = "L", label = "US" },
				{ value = "4.546", unit = "L", label = "UK" },
			},
		},
		quart = {
			name = "quart",
			system = "customary",
			category = "volume",
			symbols = { "qt" },
			forms = { "quart", "quarts" },
			results = {
				{ value = "0.946", unit = "L", label = "US" },
				{ value = "1.137", unit = "L", label = "UK" },
			},
		},
		pint = {
			name = "pint",
			system = "customary",
			category = "volume",
			symbols = { "pt" },
			forms = { "pint", "pints" },
			results = {
				{ value = "0.473", unit = "L", label = "US" },
				{ value = "0.568", unit = "L", label = "UK" },
			},
		},
		barrel = {
			name = "barrel",
			system = "customary",
			category = "volume",
			symbols = { "bbl" },
			forms = { "barrel", "barrels" },
			results = { { value = "158.99", unit = "L", label = "oil" } },
		},
	},
}
