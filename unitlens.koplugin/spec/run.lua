--[[
spec/run.lua - tiny off-device test runner for the pure core.

Run from the plugin directory:
    cd unitlens.koplugin && lua5.1 spec/run.lua
(luajit or lua5.4 also work - the core avoids version-specific features.)
]]

-- Make `require("ul_util")`, `require("dicts.en")`, etc. resolve from the plugin root.
package.path = "./?.lua;./?/init.lua;" .. package.path

-- Also look in the user-local luarocks tree so `require("lua-utf8")` (the
-- off-device Unicode lowercaser) resolves without needing `eval $(luarocks path)`.
local home = os.getenv("HOME")
local ver = _VERSION:match("%d+%.%d+") or "5.1"
if home then
	package.path = table.concat({
		home .. "/.luarocks/share/lua/" .. ver .. "/?.lua",
		home .. "/.luarocks/share/lua/" .. ver .. "/?/init.lua",
		package.path,
	}, ";")
	package.cpath = home .. "/.luarocks/lib/lua/" .. ver .. "/?.so;" .. package.cpath
end

local passed, failed = 0, 0

-- Serialize a value for comparison/printing. Handles scalars and flat arrays,
-- which is all our assertions need.
local function ser(v)
	if type(v) == "table" then
		local parts = {}
		for i = 1, #v do
			parts[i] = tostring(v[i])
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end

local t = {}

function t.eq(got, want, msg)
	if ser(got) == ser(want) then
		passed = passed + 1
	else
		failed = failed + 1
		print(string.format("  FAIL: %s\n        got:  %s\n        want: %s", msg or "?", ser(got), ser(want)))
	end
end

function t.truthy(v, msg)
	if v then
		passed = passed + 1
	else
		failed = failed + 1
		print(string.format("  FAIL: %s (expected truthy, got %s)", msg or "?", tostring(v)))
	end
end

local specs = {
	"spec.util_spec",
	"spec.dict_spec",
	"spec.matcher_spec",
	"spec.format_spec",
}

for _, name in ipairs(specs) do
	print(name)
	require(name)(t)
end

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
