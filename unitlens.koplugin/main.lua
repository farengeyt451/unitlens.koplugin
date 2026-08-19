--[[--
Unit Lens - KOReader plugin

Detects measurement units on the visible page and reveals their equivalent in
the other measurement system (values are precomputed in the dictionaries - no
runtime math).

On each page/position change we walk the visible page into word tokens
(ul_scanner), run the pure matcher against the active dictionary, and feed the
matches to ul_render, which draws an underline under each unit and shows a
tooltip on tap.

Navigation events are debounced (SCAN_DEBOUNCE) so a page turn's reflow burst
becomes a single scan of the settled page, and each page's matches are cached by
signature (page + rendering hash) so flipping back is instant and flicker-free.

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

-- Navigation fires in bursts (page turn -> partial reflow -> settle). We coalesce
-- them into a single scan once things go quiet, so we never scan a half-laid-out
-- page - that showed up in the log as a transient matches=0 that briefly cleared
-- the underlines.
local SCAN_DEBOUNCE = 0.1 -- seconds

-- Per-document cache of computed matches, keyed by page signature (page number +
-- rendering hash). Flipping back to a visited page is then instant and flicker-
-- free. FIFO-capped so a long reading session can't grow it without bound.
local SCAN_CACHE_MAX = 64

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
	self._scan_cache = {} -- sig -> render_matches
	self._scan_cache_keys = {} -- sig insertion order (FIFO eviction)
	self._scan_pending = nil -- scheduled debounce closure, if any
	self._empty_retries = 0 -- bounded retries when a page reads back empty

	-- Appearance settings are global (G_reader_settings); language is per-book
	self.enabled = settings.get("enabled")
	self.opts = {
		underline_style = settings.get("underline_style"),
		underline_thickness = settings.get("underline_thickness"),
		underline_intensity = settings.get("underline_intensity"),
		tooltip_timeout = settings.get("tooltip_timeout"),
		tooltip_text_size = settings.get("tooltip_text_size"),
		tooltip_detail = settings.get("tooltip_detail"),
	}

	-- Interface (UI) language - global, separate from the per-book dictionary
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

-- One-shot notice when the book language can't be resolved (guard per book)
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

-- --- Scan scheduling & cache ----------------------------------------------

-- Cancel a pending debounced scan, if any.
function UnitLens:_cancelPending()
	if self._scan_pending then
		pcall(function()
			UIManager:unschedule(self._scan_pending)
		end)
		self._scan_pending = nil
	end
end

-- Apply a (possibly cached) match set to the renderer and remember its page.
function UnitLens:_applyMatches(sig, render_matches)
	self.last_sig = sig
	self._last_count = #render_matches
	self._empty_retries = 0 -- page resolved; reset the reflow retry budget
	render.setMatches(self, render_matches)
end

-- Store a computed match set under its page signature (FIFO-capped).
function UnitLens:_cacheStore(sig, render_matches)
	if not sig then
		return
	end
	if self._scan_cache[sig] == nil then
		self._scan_cache_keys[#self._scan_cache_keys + 1] = sig
		while #self._scan_cache_keys > SCAN_CACHE_MAX do
			local old = table.remove(self._scan_cache_keys, 1)
			self._scan_cache[old] = nil
		end
	end
	self._scan_cache[sig] = render_matches
end

-- Drop the whole cache. Popup text (language, detailed/simple) is baked into the
-- cached matches, so those changes must invalidate everything.
function UnitLens:_clearCache()
	self._scan_cache = {}
	self._scan_cache_keys = {}
end

-- Coalesce a burst of navigation/reflow events into one scan. If the target
-- page's matches are already cached, apply them immediately (no debounce, no
-- flicker); otherwise schedule the heavy scan once events go quiet.
function UnitLens:_scheduleScan(reason, immediate)
	-- Overlay/tap handlers need self.ui.view / self.ui.highlight
	render.mount(self)

	if not self.enabled then
		self:_cancelPending()
		render.clear(self)
		return
	end

	local sig = self:_pageSig()

	-- Same page already showing -> nothing to do.
	if sig and sig == self.last_sig then
		return
	end

	-- Known page -> reuse its matches right away.
	if sig and self._scan_cache[sig] then
		self:_cancelPending()
		self:_applyMatches(sig, self._scan_cache[sig])
		log("scan(" .. tostring(reason) .. "-cache): matches=" .. #self._scan_cache[sig])
		return
	end

	self:_cancelPending()
	local fn = function()
		self._scan_pending = nil
		self:scan(reason)
	end
	self._scan_pending = fn
	UIManager:scheduleIn(immediate and 0 or SCAN_DEBOUNCE, fn)
end

function UnitLens:scan(reason)
	local doc = self.ui and self.ui.document

	if not doc then
		return
	end

	-- Overlay/tap handlers need self.ui.view / self.ui.highlight
	render.mount(self)

	if not self.enabled then
		render.clear(self)
		return
	end

	local sig = self:_pageSig()

	-- The page may have settled onto a signature we already have (a cache entry
	-- filled between scheduling and running, or a same-page late scan).
	if sig and sig == self.last_sig then
		return
	end
	if sig and self._scan_cache[sig] then
		self:_applyMatches(sig, self._scan_cache[sig])
		return
	end

	local lang = langselect.resolve(self)
	local d = lang and self.dicts[lang]

	if not d then
		self.last_sig = sig
		render.clear(self)
		self:_warnUndetected()
		log("scan(" .. tostring(reason) .. "): language undetected - none active")
		return
	end

	local page = doc.getCurrentPage and doc:getCurrentPage() or 1
	local t0 = os.clock()
	local tokens = scanner.pageTokens(doc, page)

	-- An empty token list almost always means the page is still reflowing rather
	-- than genuinely blank. Keep the current underlines and retry shortly instead
	-- of clearing them (the transient flicker seen in the log). Bounded retries.
	if #tokens == 0 and self._empty_retries < 2 then
		self._empty_retries = self._empty_retries + 1
		self:_cancelPending()
		local fn = function()
			self._scan_pending = nil
			self:scan(reason)
		end
		self._scan_pending = fn
		UIManager:scheduleIn(SCAN_DEBOUNCE, fn)
		log("scan(" .. tostring(reason) .. "): 0 tokens - deferring (retry " .. self._empty_retries .. ")")
		return
	end
	self._empty_retries = 0

	local texts = {}

	for i = 1, #tokens do
		texts[i] = tokens[i].text
	end

	local matches = matcher.match(d, texts)

	-- Turn matches into render records carrying the XPointer span (for the box)
	local detailed = self.opts.tooltip_detail ~= "simple"
	local render_matches = {}

	for _, m in ipairs(matches) do
		local tk = tokens[m.from]
		if tk then
			render_matches[#render_matches + 1] = {
				start_xp = tk.start_xp,
				end_xp = tk.end_xp,
				popup = format.popup(m.unit, d.strings, detailed),
				token = tk.text,
			}
		end
	end

	local dt = os.clock() - t0

	self:_cacheStore(sig, render_matches)
	self:_applyMatches(sig, render_matches)

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
end

-- Reader broadcasts these on navigation
function UnitLens:onPageUpdate()
	self:_scheduleScan("page")
end

function UnitLens:onPosUpdate()
	self:_scheduleScan("pos")
end

function UnitLens:onReaderReady()
	render.mount(self)
	self:_scheduleScan("ready", true)
end

-- Drop pending work when the document goes away (scheduled closures would no-op
-- anyway once self.ui.document is gone, but this is tidy and frees the cache).
function UnitLens:onCloseDocument()
	self:_cancelPending()
	self:_clearCache()
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
		self:_scheduleScan("toggle-on", true)
	else
		self:_cancelPending()
		render.clear(self)
	end
end

-- Change an appearance option
function UnitLens:setOpt(key, value)
	self.opts[key] = value
	settings.set(key, value)
	if key == "tooltip_detail" then
		-- Popup text is baked into the cached matches -> invalidate.
		self:_clearCache()
		self.last_sig = nil
		if self.enabled then
			self:_scheduleScan("opt", true)
		else
			render.clear(self)
		end
	else
		render.refresh(self)
	end
end

-- Change the Interface (UI) language ("auto" or a shipped l10n code)
function UnitLens:setUiLanguage(choice)
	self.ui_lang_choice = choice
	settings.set("ui_lang", choice)
	i18n.setLang(choice)
end

-- Change the per-book language choice ("auto" or a dict code) and rescan
function UnitLens:setLanguage(code)
	langselect.setChoice(self, code)
	self._lang_warned = nil -- allow a fresh notice if the new choice is undetectable
	self:_clearCache() -- cached matches are language-specific
	self.last_sig = nil
	if self.enabled then
		self:_scheduleScan("lang", true)
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
