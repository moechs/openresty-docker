local ngx_shared = ngx.shared
local sets = ngx_shared.sets
local cjson = require "cjson"
local pretty = require "resty.prettycjson"
local io = io
local log = ngx.log

local _M = {}

local function load_config()
    local config_data = {}
    local file, err = io.open("/etc/nginx/sets/config.json", "r")
    assert(file and not err)
    if file then
        local data = file:read("*a")
        if data and data ~= "" then
            config_data = cjson.decode(data)
        end
    end
    local ok, err = file:close()
    assert(ok and not err)
    return config_data
end

local function save_config(config_data)
    local data = "{}"
    local file, err = io.open("/etc/nginx/sets/config.json", "w")
    assert(file and not err)
    if config_data then
        data = pretty(config_data, "\n", "    ") .. "\n"
    end
    assert(file:write(data))
    local ok, err = file:close()
    assert(ok and not err)
    return config_data
end

function _M.setdefault(key, value)
    if not sets:get(key) then
        return sets:set(key, value)
    end
end

function _M.set(key, value)
    local _, err = sets:set(key, value)
    return err
end

function _M.get(key)
    return sets:get(key)
end

function _M.del(key)
    return sets:delete(key)
end

function _M.get_keys(max_count)
    return sets:get_keys(max_count or 1024)
end

function _M.load_config()
    local config_data = load_config()
    for key, value in pairs(config_data) do
        sets:set(key, value)
    end
end

function _M.save_config(max_count)
    local config_data = {}
    for _, key in pairs(sets:get_keys(max_count or 1024)) do
        config_data[key] = sets:get(key)
    end    
    save_config(config_data)
end

return _M
