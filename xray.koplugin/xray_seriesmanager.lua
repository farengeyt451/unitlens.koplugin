-- xray_seriesmanager.lua - STANDALONE series-specific logic for KOReader X-Ray
local ok, lfs = pcall(require, "libs/libkoreader-lfs")
if not ok or type(lfs) ~= "table" then
    ok, lfs = pcall(require, "lfs")
end
if not ok or type(lfs) ~= "table" then
    lfs = nil
end
local logger = require("logger")
local DataStorage = require("datastorage")

local SeriesManager = {}

function SeriesManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SeriesManager:makeSlug(name)
    if not name then return "" end
    -- Lowercase and replace non-alphanumeric characters with underscores
    local slug = name:lower():gsub("[%s%p]+", "_")
    -- Strip leading/trailing underscores
    slug = slug:gsub("^_+", ""):gsub("_+$", "")
    return slug
end

local function makeSlug(name)
    return SeriesManager:makeSlug(name)
end

-- Detect if book is part of a series
function SeriesManager:detectSeries(props, title, author, ai_helper)
    props = props or {}
    local series_name = props.series or props.Series
    local series_index = props.series_index or props.seriesindex or props.SeriesIndex
    
    logger.info("XRayPlugin: Series: detectSeries: title=" .. tostring(title) .. ", author=" .. tostring(author))
    logger.info("XRayPlugin: Series: detectSeries: Metadata check - props.series=" .. tostring(series_name) .. ", props.series_index=" .. tostring(series_index))

    -- 1. Try metadata first
    if series_name and series_name ~= "" then
        local index = tonumber(series_index) or 1
        logger.info("XRayPlugin: Series: detectSeries: Metadata path taken. Name=" .. tostring(series_name) .. ", index=" .. tostring(index))
        return {
            name = series_name,
            index = index,
            slug = makeSlug(series_name)
        }
    end
    
    -- 2. Fallback to AI
    if not ai_helper then
        logger.info("XRayPlugin: Series: detectSeries: Metadata fallback to AI skipped because ai_helper is nil")
        return nil
    end
    
    logger.info("XRayPlugin: Series: detectSeries: Metadata fallback to AI starting. Sending detection prompt.")
    local prompt = ai_helper:createPrompt(title, author, nil, "series_detect")
    local result, err_code, err_msg = ai_helper:executeUnifiedRequest(prompt)
    if result and result.is_series then
        local name = result.series_name
        local index = tonumber(result.book_index) or 1
        logger.info("XRayPlugin: Series: detectSeries: AI returned: is_series=" .. tostring(result.is_series) .. ", series_name=" .. tostring(name) .. ", book_index=" .. tostring(index))
        if name and name ~= "" then
            return {
                name = name,
                index = index,
                slug = makeSlug(name)
            }
        end
    else
        logger.info("XRayPlugin: Series: detectSeries: AI call failed or not a series. err_code=" .. tostring(err_code) .. ", err_msg=" .. tostring(err_msg))
    end
    
    logger.info("XRayPlugin: Series: detectSeries: Not part of a series.")
    return nil
end

-- Get list of prior books in the series
function SeriesManager:getPriorBookList(series_info, author, ai_helper)
    if not series_info or not series_info.name or not series_info.index or series_info.index <= 1 then
        logger.info("XRayPlugin: Series: getPriorBookList: invalid series_info or index <= 1, returning empty list")
        return {}
    end
    
    logger.info("XRayPlugin: Series: getPriorBookList starting for: " .. tostring(series_info.name) .. ", index=" .. tostring(series_info.index))

    if ai_helper then
        logger.info("XRayPlugin: Series: getPriorBookList: Sending AI prior book list prompt.")
        local context = {
            series_name = series_info.name,
            index = series_info.index
        }
        local prompt = ai_helper:createPrompt(nil, author, context, "prior_book_list")
        local result, err_code, err_msg = ai_helper:executeUnifiedRequest(prompt)
        if result and result.prior_books then
            logger.info("XRayPlugin: Series: getPriorBookList: AI returned " .. tostring(#result.prior_books) .. " prior books.")
            return result.prior_books
        else
            logger.info("XRayPlugin: Series: getPriorBookList: AI call failed or returned no list (err_code=" .. tostring(err_code) .. ", err_msg=" .. tostring(err_msg) .. "). Using local fallback.")
        end
    else
        logger.info("XRayPlugin: Series: getPriorBookList: ai_helper is nil, skipping AI prompt and using local fallback.")
    end
    
    -- Minimal local fallback if AI fails/is missing: generate placeholders
    logger.info("XRayPlugin: Series: getPriorBookList: Generating local fallback list of " .. tostring(series_info.index - 1) .. " placeholder books.")
    local fallback_list = {}
    for i = 1, series_info.index - 1 do
        table.insert(fallback_list, {
            index = i,
            title = string.format("%s (Book %d)", series_info.name, i),
            author = author or "Unknown Author"
        })
    end
    return fallback_list
end

-- Cache path for a series slug
function SeriesManager:getSeriesCachePath(slug)
    if not slug or slug == "" then return nil end
    return DataStorage:getSettingsDir() .. "/xray/series/" .. slug .. ".lua"
end

-- Ensure directory path exists
function SeriesManager:ensureDirectory(path)
    if not lfs then return true end
    local dir = path:match("(.+)/[^/]+$")
    if not dir then return false end
    
    local attr = lfs and lfs.attributes(dir)
    if attr and attr.mode == "directory" then
        return true
    end
    
    -- Use recursive mkdir (os.execute) so parent dirs are created too
    logger.info("SeriesManager: Creating directory:", dir)
    local escaped = dir:gsub("'", "'\\''")
    local rc = os.execute("mkdir -p '" .. escaped .. "'")
    if rc == 0 or rc == true then
        return true
    end

    -- Fallback: try lfs.mkdir (non-recursive, may fail if parent missing)
    if lfs then
        local success, err = lfs.mkdir(dir)
        if success then return true end
        logger.warn("SeriesManager: Failed to create directory:", err or "unknown error")
    end
    return false
end

-- Save series context to global cache
function SeriesManager:saveSeriesCache(slug, data)
    if not slug or not data then
        return false
    end
    
    local cache_file = self:getSeriesCachePath(slug)
    if not cache_file then return false end
    
    if not self:ensureDirectory(cache_file) then
        return false
    end
    
    data.cached_at = os.time()
    data.cache_version = "6.0"
    
    local success, err = pcall(function()
        local f, open_err = io.open(cache_file, "w")
        if not f then
            logger.warn("SeriesManager: Cannot open file for writing:", cache_file)
            return false
        end
        
        f:write("-- X-Ray Series Cache v6.0\n")
        f:write("return ")
        self:serializeToFile(f, data, "")
        f:write("\n")
        f:close()
        logger.info("SeriesManager: Saved series cache to:", cache_file)
        return true
    end)
    
    return success
end

-- Load series context from global cache
function SeriesManager:loadSeriesCache(slug)
    if not slug or slug == "" then return nil end
    local cache_file = self:getSeriesCachePath(slug)
    if not cache_file then return nil end
    
    if lfs then
        local attr = lfs.attributes(cache_file)
        if not attr then return nil end
    else
        local f = io.open(cache_file, "r")
        if f then f:close() else return nil end
    end
    
    local success, data = pcall(dofile, cache_file)
    if success and type(data) == "table" and data.cache_version == "6.0" then
        return data
    end
    return nil
end

-- Stream-serialize to file
function SeriesManager:serializeToFile(f, obj, indent, seen)
    seen = seen or {}
    local t = type(obj)

    if t == "table" then
        if seen[obj] then
            f:write("{--[[circular reference]]}")
            return
        end
        seen[obj] = true

        f:write("{\n")
        local child_indent = indent .. "  "
        for k, v in pairs(obj) do
            if type(v) ~= "function" and type(v) ~= "userdata" and type(v) ~= "thread" then
                f:write(child_indent)
                if type(k) == "string" then
                    if k:match("^[%a_][%w_]*$") then
                        f:write(k)
                        f:write(" = ")
                    else
                        f:write("[")
                        f:write(string.format("%q", k))
                        f:write("] = ")
                    end
                else
                    f:write("[")
                    f:write(tostring(k))
                    f:write("] = ")
                end
                self:serializeToFile(f, v, child_indent, seen)
                f:write(",\n")
            end
        end
        f:write(indent)
        f:write("}")

    elseif t == "string" then
        f:write(string.format("%q", obj))
    elseif t == "number" or t == "boolean" then
        f:write(tostring(obj))
    else
        f:write("nil")
    end
end

return SeriesManager
