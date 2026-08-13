--[[--
Unit Lens - KOReader plugin

Detects measurement units on the visible page and reveals their equivalent in
the other measurement system (values are precomputed in the dictionaries - no
runtime math).

On each page/position change we walk the visible page into word tokens
(ul_scanner), run the pure matcher against the active dictionary, and feed the
matches to ul_render, which draws an underline under each unit and shows a
tooltip on tap.

Milestone 5: a dedicated "Unit Lens ▸" submenu under Tools gathers the enable
toggle, per-book language choice (ul_langselect), underline appearance and
tooltip timeout (ul_settings), and About.

@module koplugin.unitlens
--]]

local WidgetContainer = require("ui/widget/container/widgetcontainer")
local DataStorage = require("datastorage")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local Notification = require("ui/widget/notification")
local logger = require("logger")

-- Our modules are ul_-prefixed on purpose: KOReader already owns generic names
-- like "util" (frontend/util.lua), and package.loaded is shared across plugins,
-- so a bare require("util") would return KOReader's, not ours.
local dict = require("ul_dict")
local matcher = require("ul_matcher")
local format = require("ul_format")
local scanner = require("ul_scanner")
local render = require("ul_render")
local settings = require("ul_settings")
local langselect = require("ul_langselect")
local i18n = require("ul_i18n")
local menu = require("ul_menu")

local VERSION = "0.5.0"

-- Milestone 2 is log-only. KOReader's stdout is swallowed by the emulator, so we
-- also append to a file we can tail: <data dir>/unitlens.log.
local LOG_PATH = "/tmp/unitlens.log"

do
	local ok, dir = pcall(function()
		return DataStorage:getDataDir()
	end)

	if ok and dir then
		LOG_PATH = dir .. "/unitlens.log"
	end
end

local function log(msg)
	msg = "[unitlens] " .. tostring(msg)
	logger.info(msg)

	local f = io.open(LOG_PATH, "a")

	if f then
		f:write(os.date("%H:%M:%S ") .. msg .. "\n")
		f:close()
	end
end

local UnitLens = WidgetContainer:extend({
	name = "unitlens",
	is_doc_only = true,
})

-- Pin "Unit Lens" to the TOP of the Tools tab (like X-Ray)
local function pinToToolsTop()
	pcall(function()
		local ok, order = pcall(require, "ui/elements/reader_menu_order")

		if not ok then
			ok, order = pcall(require, "apps/reader/modules/readermenuorder")
		end

		if ok and order and order.tools then
			for i, v in ipairs(order.tools) do
				if v == "unitlens" then
					table.remove(order.tools, i)
					break
				end
			end
			table.insert(order.tools, 1, "unitlens")
		end
	end)
end

-- Load and compile the built-in dictionaries once
local function loadDicts()
	local out = {}

	for _, lang in ipairs({ "en", "ru" }) do
		local ok, raw = pcall(require, "dicts." .. lang)

		if ok and raw then
			local cok, compiled = pcall(dict.compile, raw)

			if cok then
				out[lang] = compiled
			else
				log("failed to compile dict '" .. lang .. "': " .. tostring(compiled))
			end
		else
			log("failed to load dict '" .. lang .. "': " .. tostring(raw))
		end
	end
	return out
end

function UnitLens:init()
	self.dicts = loadDicts()
	self.last_sig = nil
	self._last_count = 0

	-- Appearance settings are global (G_reader_settings); language is per-book
	-- (resolved by ul_langselect). `enabled` lives in the global settings too.
	self.enabled = settings.get("enabled")
	self.opts = {
		underline_style = settings.get("underline_style"),
		underline_thickness = settings.get("underline_thickness"),
		underline_intensity = settings.get("underline_intensity"),
		tooltip_timeout = settings.get("tooltip_timeout"),
	}

	-- Interface (UI) language - global, separate from the per-book dictionary
	-- language. "auto" follows KOReader's app language; English is the fallback.
	self.ui_lang_choice = settings.get("ui_lang")
	i18n.setLang(self.ui_lang_choice)

	if self.ui and self.ui.menu then
		self.ui.menu:registerToMainMenu(self)
	end
	pinToToolsTop()

	log("initialised; dicts loaded: " .. table.concat(self:loadedLangs(), ", "))
end

function UnitLens:loadedLangs()
	local t = {}

	for k in pairs(self.dicts or {}) do
		t[#t + 1] = k
	end

	table.sort(t)
	return t
end

-- One-shot notice when the book language can't be resolved (guard per book).
function UnitLens:_warnUndetected()
	if self._lang_warned then
		return
	end
	self._lang_warned = true
	UIManager:show(Notification:new({
		text = i18n.t("Unit Lens: book language not detected - pick one in Tools ▸ Unit Lens ▸ Book language"),
		timeout = 4,
	}))
end

-- Signature so we don't rescan an unchanged page (page no + rendering hash)
function UnitLens:_pageSig()
	local doc = self.ui and self.ui.document

	if not doc then
		return nil
	end

	local page = doc.getCurrentPage and doc:getCurrentPage() or 0
	local hash = ""

	if doc.getDocumentRenderingHash then
		pcall(function()
			hash = doc:getDocumentRenderingHash()
		end)
	end
	return tostring(page) .. "|" .. tostring(hash)
end

function UnitLens:scan(reason)
	local doc = self.ui and self.ui.document

	if not doc then
		return
	end

	-- Overlay/tap handlers need self.ui.view / self.ui.highlight, which exist by
	-- reader time; mount is idempotent so calling it here is safe.
	render.mount(self)

	if not self.enabled then
		render.clear(self)
		return
	end

	local sig = self:_pageSig()

	if sig and sig == self.last_sig then
		return
	end

	self.last_sig = sig

	local lang = langselect.resolve(self)
	local d = lang and self.dicts[lang]

	if not d then
		render.clear(self)
		self:_warnUndetected()
		log("scan(" .. tostring(reason) .. "): language undetected - none active")
		return
	end

	local page = doc.getCurrentPage and doc:getCurrentPage() or 1
	local t0 = os.clock()
	local tokens = scanner.pageTokens(doc, page)
	local texts = {}

	for i = 1, #tokens do
		texts[i] = tokens[i].text
	end

	local matches = matcher.match(d, texts)

	-- Turn matches into render records carrying the XPointer span (for the box)
	-- and the precomputed popup text (for the tooltip).
	local render_matches = {}

	for _, m in ipairs(matches) do
		local tk = tokens[m.from]
		if tk then
			render_matches[#render_matches + 1] = {
				start_xp = tk.start_xp,
				end_xp = tk.end_xp,
				popup = format.popup(m.unit, d.strings),
				token = tk.text,
			}
		end
	end

	local dt = os.clock() - t0

	render.setMatches(self, render_matches)

	log(
		string.format(
			"scan(%s): page=%s lang=%s tokens=%d matches=%d (%.3fs)",
			tostring(reason),
			tostring(page),
			lang,
			#tokens,
			#matches,
			dt
		)
	)

	self._last_count = #matches
end

-- Reader broadcasts these on navigation
function UnitLens:onPageUpdate()
	self:scan("page")
end

function UnitLens:onPosUpdate()
	self:scan("pos")
end

function UnitLens:onReaderReady()
	render.mount(self)
	self:scan("ready")
end

function UnitLens:addToMainMenu(menu_items)
	menu_items.unitlens = menu.build(self)
end

-- --- Menu callbacks --------------------------------------------------------

-- Enable/disable highlighting (global setting).
function UnitLens:setEnabled(value)
	self.enabled = value
	settings.set("enabled", value)
	if value then
		self.last_sig = nil -- force a rescan of the current page
		self:scan("toggle-on")
	else
		render.clear(self)
	end
end

-- Change an appearance option (style/thickness/intensity/tooltip_timeout).
-- These don't affect which units match, so just repaint - no rescan.
function UnitLens:setOpt(key, value)
	self.opts[key] = value
	settings.set(key, value)
	render.refresh(self)
end

-- Change the Interface (UI) language ("auto" or a shipped l10n code). Menu labels
-- are rebuilt on the next menu open; nothing on the page needs to change.
function UnitLens:setUiLanguage(choice)
	self.ui_lang_choice = choice
	settings.set("ui_lang", choice)
	i18n.setLang(choice)
end

-- Change the per-book language choice ("auto" or a dict code) and rescan.
function UnitLens:setLanguage(code)
	langselect.setChoice(self, code)
	self._lang_warned = nil -- allow a fresh notice if the new choice is undetectable
	self.last_sig = nil
	if self.enabled then
		self:scan("lang")
	else
		render.clear(self)
	end
end

function UnitLens:showAbout()
	local text = table.concat({
		"",
		"Unit Lens v" .. VERSION,
		"",
		i18n.t("about_description"),
		"",
		i18n.t("about_dicts"),
		"",
		i18n.t("Author") .. ":" .. " " .. "Alexander Kislov",
		"",
	}, "\n")
	UIManager:show(InfoMessage:new({ text = text }))
end

return UnitLens
