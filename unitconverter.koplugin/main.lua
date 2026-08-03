--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]
--

-- This is a debug plugin, remove the following if block to enable it
-- if true then
-- 	return { disabled = true }
-- end

local Dispatcher = require("dispatcher") -- luacheck:ignore
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local Hello = WidgetContainer:extend({
	name = "hello",
	is_doc_only = false,
})

-- Truncate `s` to at most `max_chars` UTF-8 characters (not bytes).
-- The pattern matches one UTF-8 lead byte followed by its continuation bytes,
-- so we never split a multibyte character in half.
local function utf8Truncate(s, max_chars)
	local count = 0
	local out = {}
	for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		count = count + 1
		if count > max_chars then
			out[#out + 1] = " ..."
			break
		end
		out[#out + 1] = ch
	end
	return table.concat(out)
end

function Hello:onDispatcherRegisterActions()
	Dispatcher:registerAction(
		"helloworld_action",
		{ category = "none", event = "HelloWorld", title = _("Hello World"), general = true }
	)
end

function Hello:init()
	self:onDispatcherRegisterActions()
	self.ui.menu:registerToMainMenu(self)
end

function Hello:addToMainMenu(menu_items)
	menu_items.hello_world = {
		text = _("Hello World"),
		-- in which menu this should be appended
		sorting_hint = "more_tools",
		-- a callback when tapping
		callback = function()
			UIManager:show(InfoMessage:new({
				text = self:showPageContent(),
			}))
		end,
	}
end

function Hello:onHelloWorld()
	local popup = InfoMessage:new({
		text = _("Hello World"),
	})
	UIManager:show(popup)
end

function Hello:showPageContent()
	-- Step 4: extract the current page's text the crengine (EPUB) way, using
	-- XPointers instead of getPageText (which only works for paged PDFs/DjVu).
	local doc = self.ui and self.ui.document
	if not doc then
		return "No document open. Open a book first."
	end

	local page = doc:getCurrentPage()
	local total = doc.info and doc.info.number_of_pages

	local ok, text = pcall(function()
		local start_xp = doc:getPageXPointer(page)
		-- End at the start of the next page; clamp so we don't run past the book.
		local next_page = page + 1
		if total and next_page > total then
			next_page = total
		end
		local end_xp = doc:getPageXPointer(next_page)
		return doc:getTextFromXPointers(start_xp, end_xp)
	end)

	if not ok then
		return "extraction errored on page " .. tostring(page) .. ":\n" .. tostring(text)
	end

	if not text or text == "" then
		return "No text extracted on page " .. tostring(page) .. "."
	end

	-- Keep the popup readable while we're testing. Truncate on UTF-8 character
	-- boundaries (NOT bytes) so multibyte chars like Cyrillic aren't split.
	text = utf8Truncate(text, 200)
	return "page " .. tostring(page) .. ":\n" .. text
end

return Hello
