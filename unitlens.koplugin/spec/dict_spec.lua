return function(t)
	local dict = require("ul_dict")
	local en = dict.compile(require("dicts.en"))
	local ru = dict.compile(require("dicts.ru"))

	-- forms flatten to casefolded keys, mapped to the right unit
	t.eq(en.forms["feet"].key, "foot", "en: feet -> foot")
	t.eq(en.forms["inches"].key, "inch", "en: inches -> inch")
	t.truthy(en.forms["FEET"] == nil, "en: forms keys are casefolded (no FEET)")

	-- symbols are case-sensitive and mapped to the right unit
	t.eq(en.symbols["mm"].key, "millimetre", "en: mm -> millimetre")
	t.eq(en.symbols["ft"].key, "foot", "en: ft -> foot")

	-- ru: a full inflected form resolves; metric symbol present
	t.eq(ru.forms["футах"].key, "foot", "ru: футах -> foot")
	t.eq(ru.forms["милями"].key, "mile", "ru: милями -> mile")
	t.eq(ru.symbols["см"].key, "centimetre", "ru: см -> centimetre")

	-- identity fields survive compile
	t.eq(en.lang, "en", "en lang")
	t.eq(ru.name, "Русский", "ru endonym")
end
