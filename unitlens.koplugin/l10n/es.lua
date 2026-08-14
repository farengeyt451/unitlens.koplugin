--[[
l10n/es.lua - Spanish. Keys are the English source strings (see l10n/en.lua)
]]

return {
	name = "Español",
	strings = {
		-- Menu
		["Highlight measurement units"] = "Resaltar unidades de medida",
		["Book language"] = "Idioma del libro",
		["Interface language"] = "Idioma de la interfaz",
		["Underline style"] = "Estilo de subrayado",
		["Underline thickness"] = "Grosor del subrayado",
		["Underline intensity"] = "Intensidad del subrayado",
		["Tooltip timeout"] = "Duración del aviso",
		["Tooltip text size"] = "Tamaño del texto del aviso",
		["Tooltip content"] = "Contenido del aviso",
		["About"] = "Acerca de",

		-- Language pickers
		["Auto (from book)"] = "Auto (del libro)",
		["Auto (system)"] = "Auto (según la app)",

		-- Tooltip text size (relative to the book's font size)
		["Auto (follow book)"] = "Auto (según el libro)",
		["Smallest"] = "El más pequeño",
		["Smaller"] = "Más pequeño",
		["Bigger"] = "Más grande",
		["Biggest"] = "El más grande",

		-- Tooltip content
		["Detailed"] = "Detallado",
		["Simple"] = "Simple",

		-- Underline styles
		["Wavy"] = "Ondulado",
		["Solid"] = "Sólido",
		["Dotted"] = "Punteado",
		["Dashed"] = "Discontinuo",
		["Double"] = "Doble",
		["None"] = "Ninguno",

		-- Thickness (px is universal - left to fall back to English)

		-- Intensity
		["Light"] = "Claro",
		["Medium"] = "Medio",
		["Dark"] = "Oscuro",

		-- Tooltip timeout
		["2 seconds"] = "2 segundos",
		["4 seconds"] = "4 segundos",
		["8 seconds"] = "8 segundos",
		["Never"] = "Nunca se cierra automáticamente",

		-- About
		["about_description"] = "Detecta unidades de medida mientras lees y muestra su equivalente en el otro sistema - sin conexión, basado en diccionarios (sin cálculos en tiempo real)",
		["about_dicts"] = "Diccionarios integrados: ruso y inglés. Añade los tuyos en la carpeta dicts/ del plugin",
		["Author"] = "Autor",

		-- Notifications
		["Unit Lens: book language not detected - pick one in Tools ▸ Unit Lens ▸ Book language"] = "Unit Lens: no se detectó el idioma del libro - elígelo en «Herramientas ▸ Unit Lens ▸ Idioma del libro»",
	},
}
