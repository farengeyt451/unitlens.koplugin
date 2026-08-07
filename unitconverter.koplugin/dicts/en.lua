--[[
dicts/en.lua — English dictionary (length subset for Milestone 1).

Format: see docs/spec.md §4. Values are precomputed strings (docs/units.md).
Customary units convert -> metric; metric units convert -> customary.
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

		-- Customary -> metric
		inch = {
			name = "inch",
			system = "customary",
			category = "length",
			forms = { "inch", "inches" },
			symbols = { "in", "″" },
			results = { { value = "2.54", unit = "cm" } },
		},
		foot = {
			name = "foot",
			system = "customary",
			category = "length",
			forms = { "foot", "feet" },
			symbols = { "ft", "′" },
			results = { { value = "0.3048", unit = "m" } },
		},
		yard = {
			name = "yard",
			system = "customary",
			category = "length",
			forms = { "yard", "yards" },
			symbols = { "yd" },
			results = { { value = "0.9144", unit = "m" } },
		},
		mile = {
			name = "mile",
			system = "customary",
			category = "length",
			forms = { "mile", "miles" },
			symbols = { "mi" },
			results = { { value = "1.609", unit = "km" } },
		},

		-- Metric -> customary
		millimetre = {
			name = "mm",
			system = "metric",
			category = "length",
			forms = { "millimetre", "millimetres", "millimeter", "millimeters" },
			symbols = { "mm" },
			results = { { value = "0.0394", unit = "in" } },
		},
		centimetre = {
			name = "cm",
			system = "metric",
			category = "length",
			forms = { "centimetre", "centimetres", "centimeter", "centimeters" },
			symbols = { "cm" },
			results = { { value = "0.3937", unit = "in" } },
		},
		metre = {
			name = "m",
			system = "metric",
			category = "length",
			forms = { "metre", "metres", "meter", "meters" },
			symbols = { "m" },
			results = { { value = "3.2808", unit = "ft" } },
		},
		kilometre = {
			name = "km",
			system = "metric",
			category = "length",
			forms = { "kilometre", "kilometres", "kilometer", "kilometers" },
			symbols = { "km" },
			results = { { value = "0.6214", unit = "mi" } },
		},
	},
}
