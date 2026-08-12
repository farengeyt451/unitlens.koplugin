--[[--
Unit Lens — KOReader plugin

Detects measurement units on the visible page and reveals their equivalent in
the other measurement system (values are precomputed in the dictionaries — no
runtime math).

Milestone 2: live scan, log only. On each page/position change we walk the
visible page into word tokens (ul_scanner), run the pure matcher against the
active dictionary, and LOG every match with its popup text. No underline/tooltip
rendering yet — this milestone just proves the device scan.

@module koplugin.unitlens
--]]

local WidgetContainer = require("ui/widget/container/widgetcontainer")
local DataStorage = require("datastorage")
local logger = require("logger")
local _ = require("gettext")

-- Our modules are ul_-prefixed on purpose: KOReader already owns generic names
-- like "util" (frontend/util.lua), and package.loaded is shared across plugins,
-- so a bare require("util") would return KOReader's, not ours.
local dict = require("ul_dict")
local matcher = require("ul_matcher")
local format = require("ul_format")
local scanner = require("ul_scanner")
local render = require("ul_render")

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
	self.enabled = true

	if self.ui and self.ui.menu then
		self.ui.menu:registerToMainMenu(self)
	end

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

-- Temporary language pick (real langselect is Milestone 5): book metadata's
-- primary subtag, else English fallback.
function UnitLens:pickLang()
	local doc = self.ui and self.ui.document
	if doc and doc.getProps then
		local ok, props = pcall(function()
			return doc:getProps()
		end)
		if ok and props and props.language and props.language ~= "" then
			local lang = tostring(props.language):sub(1, 2):lower()
			if self.dicts[lang] then
				return lang
			end
		end
	end
	if self.dicts.en then
		return "en"
	end
	return self:loadedLangs()[1]
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

	local lang = self:pickLang()
	local d = lang and self.dicts[lang]

	if not d then
		log("scan(" .. tostring(reason) .. "): no active dictionary")
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
	menu_items.unitlens = {
		text = _("Highlight measurement units"),
		checked_func = function()
			return self.enabled
		end,
		callback = function()
			self.enabled = not self.enabled
			if self.enabled then
				self.last_sig = nil -- force a rescan of the current page
				self:scan("toggle-on")
			else
				render.clear(self)
			end
		end,
		sorting_hint = "more_tools",
	}
end

return UnitLens
