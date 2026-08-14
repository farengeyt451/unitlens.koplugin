--[[
l10n/ru.lua - Russian. Keys are the English source strings (see l10n/en.lua)
]]

return {
	name = "Русский",
	strings = {
		-- Menu
		["Highlight measurement units"] = "Подсвечивать единицы измерения",
		["Book language"] = "Язык книги",
		["Interface language"] = "Язык интерфейса",
		["Underline style"] = "Стиль подчёркивания",
		["Underline thickness"] = "Толщина подчёркивания",
		["Underline intensity"] = "Насыщенность подчёркивания",
		["Tooltip timeout"] = "Время подсказки",
		["Tooltip text size"] = "Размер текста подсказки",
		["Tooltip content"] = "Стиль подсказки",
		["About"] = "О плагине",

		-- Language pickers
		["Auto (from book)"] = "Авто (из книги)",
		["Auto (system)"] = "Авто (как в приложении)",

		-- Tooltip text size (relative to the book's font size)
		["Auto (follow book)"] = "Авто (как в книге)",
		["Smallest"] = "Самый мелкий",
		["Smaller"] = "Мельче",
		["Bigger"] = "Крупнее",
		["Biggest"] = "Самый крупный",

		-- Tooltip content
		["Detailed"] = "Подробная",
		["Simple"] = "Краткая",

		-- Underline styles
		["Wavy"] = "Волнистое",
		["Solid"] = "Сплошное",
		["Dotted"] = "Точечное",
		["Dashed"] = "Штриховое",
		["Double"] = "Двойное",
		["None"] = "Нет",

		-- Thickness
		["1 px"] = "1 px",
		["2 px"] = "2 px",
		["3 px"] = "3 px",

		-- Intensity
		["Light"] = "Светлое",
		["Medium"] = "Среднее",
		["Dark"] = "Тёмное",

		-- Tooltip timeout
		["2 seconds"] = "2 секунды",
		["4 seconds"] = "4 секунды",
		["8 seconds"] = "8 секунд",
		["Never"] = "Не закрывать автоматически",

		-- About
		["about_description"] = "Определяет единицы измерения во время чтения и показывает их эквивалент в другой системе мер - офлайн, на основе словарей",
		["about_dicts"] = "Встроенные словари: русский, английский. Добавляйте свои в папку dicts/ плагина",
		["Author"] = "Автор",

		-- Notifications
		["Unit Lens: book language not detected - pick one in Tools ▸ Unit Lens ▸ Book language"] = "Unit Lens: язык книги не определён - выберите его в «Инструменты ▸ Unit Lens ▸ Язык книги»",
	},
}
