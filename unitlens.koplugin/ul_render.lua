--[[
ul_render.lua - KOReader rendering layer for Unit Lens
]]

local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")
local Geom = require("ui/geometry")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local TextBoxWidget = require("ui/widget/textboxwidget")
local RenderText = require("ui/rendertext")
local GestureRange = require("ui/gesturerange")
local logger = require("logger")

local M = {}

-- ---------------------------------------------------------------------------
-- Tooltip widget
-- ---------------------------------------------------------------------------

local Tooltip = InputContainer:extend({
	text = nil,
	box = nil, -- { x, y, w, h } of the tapped unit, for positioning
	timeout = 6,
})

function Tooltip:init()
	local sw, sh = Screen:getWidth(), Screen:getHeight()
	local sc = function(n)
		return Screen:scaleBySize(n)
	end

	local face = Font:getFace("infofont", sc(15))

	-- Size the card to its content: measure the widest line so single-line rows
	-- (the "System: …" / "Category: …" headers) don't wrap, but cap at the screen
	local text = self.text or ""
	local widest = sc(80)

	for line in (text .. "\n"):gmatch("(.-)\n") do
		local w = RenderText:sizeUtf8Text(0, sw, face, line, true, false).x
		if w > widest then
			widest = w
		end
	end

	local content_w = math.min(widest, sw - sc(40))

	local body = TextBoxWidget:new({
		text = text,
		face = face,
		width = content_w,
		alignment = "left",
	})

	local card = FrameContainer:new({
		background = Blitbuffer.COLOR_WHITE,
		color = Blitbuffer.COLOR_DARK_GRAY,
		bordersize = sc(2),
		radius = sc(6),
		padding = sc(10),
		body,
	})

	local cs = card:getSize()
	local cw, ch = cs.w, cs.h
	local margin = sc(8)
	local box = self.box or { x = 0, y = 0, w = 0, h = 0 }

	-- Horizontally centered on the word, clamped to the screen
	local x = math.floor(box.x + box.w / 2 - cw / 2)
	x = math.max(sc(2), math.min(sw - cw - sc(2), x))

	-- Below the word if it fits, otherwise above
	local y

	if box.y + box.h + margin + ch <= sh then
		y = box.y + box.h + margin
	else
		y = box.y - margin - ch
	end

	y = math.max(sc(2), math.min(sh - ch - sc(2), y))

	card.overlap_offset = { x, y }

	self.dimen = Geom:new({ x = 0, y = 0, w = sw, h = sh })
	self.ges_events = {
		TapClose = { GestureRange:new({ ges = "tap", range = self.dimen }) },
	}

	self[1] = OverlapGroup:new({
		dimen = Geom:new({ w = sw, h = sh }),
		card,
	})
end

function Tooltip:onTapClose()
	self:dismiss()
	return true
end

function Tooltip:onClose()
	self:dismiss()
	return true
end

function Tooltip:dismiss()
	if self._timer then
		pcall(function()
			UIManager:unschedule(self._timer)
		end)
		self._timer = nil
	end

	if not self._closed then
		self._closed = true
		UIManager:close(self)
	end
end

function Tooltip:onShow()
	if self.timeout and self.timeout > 0 then
		local this = self
		self._timer = function()
			if not this._closed then
				this:dismiss()
			end
		end
		UIManager:scheduleIn(self.timeout, self._timer)
	end

	UIManager:setDirty(self, "ui")

	return true
end

function Tooltip:onCloseWidget()
	if self._timer then
		pcall(function()
			UIManager:unschedule(self._timer)
		end)

		self._timer = nil
	end
end

-- ---------------------------------------------------------------------------
-- Underline drawing
-- ---------------------------------------------------------------------------

-- Intensity -> 8-bit grey (0 = black, 255 = white)
local INTENSITY = {
	light = Blitbuffer.Color8(0xB0),
	medium = Blitbuffer.Color8(0x70),
	dark = Blitbuffer.Color8(0x20),
}

local function draw_solid(bb, box, color, th)
	bb:paintRect(box.x, box.y + box.h - th, box.w, th, color)
end

local function draw_double(bb, box, color, th)
	local line = math.max(1, math.floor(th / 2 + 0.5))
	local gap = line
	local y = box.y + box.h - line

	bb:paintRect(box.x, y, box.w, line, color)
	bb:paintRect(box.x, y - gap - line, box.w, line, color)
end

local function draw_dotted(bb, box, color, th)
	local step = th * 2
	local y = box.y + box.h - th
	local x1 = box.x + box.w
	local x = box.x

	while x < x1 do
		bb:paintRect(x, y, math.min(th, x1 - x), th, color)
		x = x + step
	end
end

local function draw_dashed(bb, box, color, th)
	local dash = math.max(2, Screen:scaleBySize(6))
	local gap = math.max(1, Screen:scaleBySize(3))
	local y = box.y + box.h - th
	local x1 = box.x + box.w
	local x = box.x

	while x < x1 do
		bb:paintRect(x, y, math.min(dash, x1 - x), th, color)
		x = x + dash + gap
	end
end

local function draw_wavy(bb, box, color, th)
	local amp = math.max(1, Screen:scaleBySize(2))
	local period = math.max(2, Screen:scaleBySize(6))
	local base = box.y + box.h - th - amp
	local x1 = box.x + box.w
	local twopi = 2 * math.pi

	for x = box.x, x1 - 1 do
		local dy = math.floor(amp * math.sin((x - box.x) / period * twopi) + 0.5)
		bb:paintRect(x, base + dy, 1, th, color)
	end
end

local DRAW = {
	solid = draw_solid,
	double = draw_double,
	dotted = draw_dotted,
	dashed = draw_dashed,
	wavy = draw_wavy,
}

-- Draw one box's underline according to the plugin's appearance settings
local function draw_underline(bb, box, opts)
	local style = opts.underline_style or "wavy"
	if style == "none" then
		return
	end

	local fn = DRAW[style] or draw_wavy
	local color = INTENSITY[opts.underline_intensity] or INTENSITY.medium
	local th = math.max(1, Screen:scaleBySize(opts.underline_thickness or 2))

	fn(bb, box, color, th)
end

-- ---------------------------------------------------------------------------
-- Box resolution (cached)
-- ---------------------------------------------------------------------------

local function box_sig(plugin)
	local doc = plugin.ui and plugin.ui.document
	if not doc then
		return ""
	end

	local page = doc.getCurrentPage and doc:getCurrentPage() or 0
	local hash = ""

	if doc.getDocumentRenderingHash then
		pcall(function()
			hash = doc:getDocumentRenderingHash()
		end)
	end

	return table.concat({ tostring(page), tostring(hash), Screen:getWidth(), Screen:getHeight() }, "|")
end

local function resolve_boxes(plugin)
	local sig = box_sig(plugin)

	if plugin._ul_box_sig == sig and plugin._ul_boxes then
		return
	end

	plugin._ul_box_sig = sig

	local doc = plugin.ui and plugin.ui.document
	local out = {}

	if doc and plugin._ul_matches then
		for _, m in ipairs(plugin._ul_matches) do
			-- A word may wrap across lines -> several boxes.
			local ok, boxes = pcall(doc.getScreenBoxesFromPositions, doc, m.start_xp, m.end_xp, true)
			if ok and boxes then
				for _, b in ipairs(boxes) do
					out[#out + 1] = { x = b.x, y = b.y, w = b.w, h = b.h, popup = m.popup }
				end
			end
		end
	end
	plugin._ul_boxes = out
end

local function set_dirty(plugin)
	local ui = plugin.ui

	if ui and ui.view then
		UIManager:setDirty(ui.view.dialog or ui, "ui")
	else
		UIManager:setDirty("all", "ui")
	end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Replace the current match set (called by main:scan). Each match:
--   { start_xp, end_xp, popup, token }
function M.setMatches(plugin, matches)
	plugin._ul_matches = matches or {}
	plugin._ul_boxes = nil
	plugin._ul_box_sig = nil
	set_dirty(plugin)
end

function M.clear(plugin)
	plugin._ul_matches = {}
	plugin._ul_boxes = {}
	plugin._ul_box_sig = nil
	set_dirty(plugin)
end

-- Repaint without recomputing matches/boxes (used after an appearance change)
function M.refresh(plugin)
	set_dirty(plugin)
end

function M.mount(plugin)
	M.mountOverlay(plugin)
	M.mountTapHandler(plugin)
end

function M.mountOverlay(plugin)
	if plugin._ul_paint_wrapped then
		return
	end

	local view = plugin.ui and plugin.ui.view

	if not view then
		logger.info("[unitlens] render: no ui.view to wrap yet")
		return
	end

	local orig = view.paintTo
	view.paintTo = function(view_self, bb, x, y)
		orig(view_self, bb, x, y) -- draw the reader page first
		local ok, err = pcall(function()
			if not plugin.enabled then
				return
			end
			local opts = plugin.opts or {}
			if opts.underline_style == "none" then
				return
			end
			resolve_boxes(plugin)
			local boxes = plugin._ul_boxes
			if not boxes or #boxes == 0 then
				return
			end
			for _, b in ipairs(boxes) do
				if b.x and b.y and b.w and b.h then
					draw_underline(bb, b, opts)
				end
			end
		end)
		if not ok then
			logger.warn("[unitlens] render draw error: " .. tostring(err))
		end
	end

	plugin._ul_paint_wrapped = true
	logger.info("[unitlens] render: paintTo overlay mounted")
end

function M.mountTapHandler(plugin)
	if plugin._ul_tap_wrapped then
		return
	end

	local hl = plugin.ui and plugin.ui.highlight

	if not hl then
		logger.info("[unitlens] render: no ui.highlight to wrap yet")
		return
	end

	local orig_tap = hl.onTap

	hl.onTap = function(hl_self, _, ges)
		if ges and M.handleTap(plugin, ges) then
			return true
		end
		if orig_tap then
			return orig_tap(hl_self, _, ges)
		end
	end

	plugin._ul_tap_wrapped = true
	logger.info("[unitlens] render: tap handler mounted")
end

function M.handleTap(plugin, ges)
	if not plugin.enabled then
		return false
	end

	local boxes = plugin._ul_boxes

	if not boxes or #boxes == 0 then
		return false
	end
	if not (ges and ges.pos) then
		return false
	end

	local tx, ty = ges.pos.x, ges.pos.y
	local tol = Screen:scaleBySize(8)

	for _, b in ipairs(boxes) do
		if tx >= b.x - tol and tx <= b.x + b.w + tol and ty >= b.y - tol and ty <= b.y + b.h + tol then
			M.showTooltip(plugin, b)
			return true
		end
	end
	return false
end

function M.showTooltip(plugin, box)
	if not box or not box.popup then
		return
	end
	-- 0 (Never) disables auto-dismiss; the user taps to close
	local timeout = (plugin.opts and plugin.opts.tooltip_timeout) or 4
	UIManager:show(Tooltip:new({
		text = box.popup,
		box = box,
		timeout = timeout,
	}))
end

return M
