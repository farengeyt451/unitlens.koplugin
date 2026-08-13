--[[
ul_langselect.lua — active-language resolution + the Language submenu
]]

local _ = require("gettext")

local M = {}

local SIDECAR_KEY = "unitlens_lang"

-- Menu label for a dict code: the dictionary's own `name` field
function M.displayName(plugin, code)
	local d = plugin.dicts and plugin.dicts[code]

	if d and d.name and d.name ~= "" then
		return d.name
	end
	return tostring(code):upper()
end

local function doc_settings(plugin)
	local ds = plugin.ui and plugin.ui.doc_settings

	if ds and ds.readSetting and ds.saveSetting then
		return ds
	end
	return nil
end

-- Current choice: "auto" or a dict code
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

-- Resolve the active dict code, or nil if undetectable
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

-- Build the radio items for the Language submenu
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
			text = M.displayName(plugin, code),
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
