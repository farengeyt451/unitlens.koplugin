--[[
ul_langselect.lua — active-language resolution + the Language submenu.

Resolution order for the active dictionary code:
  1. per-book override in the document sidecar (unless "auto")
  2. "auto": the book metadata's primary language subtag (doc:getProps().language)
  3. nil — undetectable (main.lua prompts the user to pick one)

The per-book choice is stored in the document sidecar (DocSettings) as
`unitlens_lang` = "auto" or a dictionary code (e.g. "ru"). Appearance settings are
NOT here — those are global (see ul_settings.lua).
]]

local _ = require("gettext")

local M = {}

local SIDECAR_KEY = "unitlens_lang"

-- Human-readable names for the languages we might ship/see. Unknown codes fall
-- back to the uppercased code, so user dicts still get a sensible menu label.
local NAMES = {
	en = "English",
	ru = "Russian",
	es = "Spanish",
	de = "German",
	fr = "French",
	uk = "Ukrainian",
	pl = "Polish",
	it = "Italian",
	pt = "Portuguese",
	nl = "Dutch",
	tr = "Turkish",
	cs = "Czech",
	sv = "Swedish",
	fi = "Finnish",
}

function M.displayName(code)
	return NAMES[code] or tostring(code):upper()
end

local function doc_settings(plugin)
	local ds = plugin.ui and plugin.ui.doc_settings
	if ds and ds.readSetting and ds.saveSetting then
		return ds
	end
	return nil
end

-- Current choice: "auto" or a dict code.
function M.getChoice(plugin)
	local ds = doc_settings(plugin)
	if ds then
		local v = ds:readSetting(SIDECAR_KEY)
		if v then
			return v
		end
	end
	return "auto"
end

function M.setChoice(plugin, code)
	local ds = doc_settings(plugin)
	if ds then
		ds:saveSetting(SIDECAR_KEY, code) -- flushed with the book on close
	end
end

-- Resolve the active dict code, or nil if undetectable.
function M.resolve(plugin)
	local dicts = plugin.dicts or {}
	local choice = M.getChoice(plugin)

	if choice and choice ~= "auto" then
		if dicts[choice] then
			return choice
		end
		-- stale override (dict removed) -> fall through to auto
	end

	local doc = plugin.ui and plugin.ui.document
	if doc and doc.getProps then
		local ok, props = pcall(function()
			return doc:getProps()
		end)
		if ok and props and props.language and props.language ~= "" then
			local code = tostring(props.language):sub(1, 2):lower()
			if dicts[code] then
				return code
			end
		end
	end

	return nil
end

-- Build the radio items for the Language submenu.
function M.menuItems(plugin)
	local items = {
		{
			text = _("Auto (from book)"),
			radio = true,
			checked_func = function()
				return M.getChoice(plugin) == "auto"
			end,
			callback = function()
				plugin:setLanguage("auto")
			end,
			keep_menu_open = true,
		},
	}

	local codes = {}
	for code in pairs(plugin.dicts or {}) do
		codes[#codes + 1] = code
	end
	table.sort(codes)

	for _, code in ipairs(codes) do
		items[#items + 1] = {
			text = M.displayName(code),
			radio = true,
			checked_func = function()
				return M.getChoice(plugin) == code
			end,
			callback = function()
				plugin:setLanguage(code)
			end,
			keep_menu_open = true,
		}
	end

	return items
end

return M
