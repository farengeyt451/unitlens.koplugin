--[[
ul_i18n.lua - the plugin's own UI translation layer.

This is SEPARATE from the book/dictionary language (ul_langselect): it translates
the plugin's own menu, About and notifications. It is a global setting, defaulting
to "auto" (follow KOReader's app language) with English as the fallback.

Translations live in l10n/<code>.lua as `{ name = <endonym>, strings = { [english] = translated } }`.
Keys are the English source string; any missing key falls back to English. New
languages are auto-discovered by scanning the l10n/ folder - no registry to edit.

Usage:
  local i18n = require("ul_i18n")
  i18n.setLang(choice)   -- "auto" or a code; resolves + activates
  i18n.t("About")        -- translated string (English fallback)
]]

local lfs = require("libs/libkoreader-lfs")

local M = {}

local BASE = "en"

-- Languages we ship. Auto-discovery (below) also picks up user-added files; this
-- list just guarantees the built-ins show even if directory scanning is unhappy.
local SHIPPED = { "en", "ru", "es" }

local cache = {} -- code -> module table | false (miss)
local active_strings = nil
local active_code = BASE

-- Absolute path of this plugin's directory, derived from this file's own path.
local function plugin_dir()
	local src = debug.getinfo(1, "S").source or ""
	src = src:gsub("^@", "")
	return src:match("^(.*)/[^/]*$")
end

local function load(code)
	if cache[code] ~= nil then
		return cache[code]
	end
	local ok, mod = pcall(require, "l10n." .. code)
	if ok and type(mod) == "table" and type(mod.strings) == "table" then
		cache[code] = mod
	else
		cache[code] = false
	end
	return cache[code]
end

-- Shipped + discovered UI language codes (only those that load successfully).
function M.available()
	local seen, out = {}, {}
	local function add(code)
		if not seen[code] and load(code) then
			seen[code] = true
			out[#out + 1] = code
		end
	end

	for _, code in ipairs(SHIPPED) do
		add(code)
	end

	local dir = plugin_dir()
	if dir then
		pcall(function()
			for f in lfs.dir(dir .. "/l10n") do
				local code = f:match("^(%a[%w_]*)%.lua$")
				if code then
					add(code)
				end
			end
		end)
	end

	table.sort(out)
	return out
end

-- Menu label for a UI language code: the file's own `name` endonym.
function M.displayName(code)
	local mod = load(code)
	if mod and mod.name and mod.name ~= "" then
		return mod.name
	end
	return tostring(code):upper()
end

-- Resolve "auto"/code to a concrete shipped code (English fallback).
function M.resolve(choice)
	local code = choice
	if not code or code == "auto" then
		local sys = G_reader_settings and G_reader_settings:readSetting("language")
		code = sys and tostring(sys):sub(1, 2):lower() or BASE
	end
	if not load(code) then
		code = BASE
	end
	return code
end

function M.setLang(choice)
	active_code = M.resolve(choice)
	local mod = load(active_code)
	active_strings = mod and mod.strings or nil
end

function M.activeCode()
	return active_code
end

function M.t(s)
	if active_strings then
		local v = active_strings[s]
		if v ~= nil and v ~= "" then
			return v
		end
	end
	return s
end

-- Radio items for the Interface language submenu (Auto + one per shipped code).
function M.menuItems(plugin)
	local items = {
		{
			text = M.t("Auto (system)"),
			radio = true,
			checked_func = function()
				return plugin.ui_lang_choice == "auto"
			end,
			callback = function()
				plugin:setUiLanguage("auto")
			end,
			keep_menu_open = true,
		},
	}

	for _, code in ipairs(M.available()) do
		items[#items + 1] = {
			text = M.displayName(code),
			radio = true,
			checked_func = function()
				return plugin.ui_lang_choice == code
			end,
			callback = function()
				plugin:setUiLanguage(code)
			end,
			keep_menu_open = true,
		}
	end

	return items
end

return M
