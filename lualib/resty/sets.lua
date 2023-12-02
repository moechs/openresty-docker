local io = io
local cjson = require "cjson"
local prettycjson = require "resty.prettycjson"
local sets = ngx.shared.sets
local config_file = "/etc/nginx/sets/config.json"

local _M = { version = "0.0.1" }

local function load_config(config_file)
    local file, err = io.open(config_file, "r")
    if not file then
        ngx.log(ngx.ERR, "failed to open " .. config_file .. ": ", err)
        return nil, err
    end
    local jsondata, err_read = file:read("*a")
    file:close()
    if err_read then
        ngx.log(ngx.ERR, "failed to read data from " .. config_file .. ": ", err_read)
        return nil, err_read
    end
    if jsondata and jsondata ~= "" then
        return cjson.decode(jsondata)
    end
    return nil, "failed to load " .. config_file .. ": empty file"
end

local function save_config(config_file, data)
    local jsondata, err = prettycjson(data, "\n", "    ") .. "\n"
    if err then
        ngx.log(ngx.ERR, err)
        return false, err
    end
    local file, err_open = io.open(config_file, "w")
    if err_open then
        ngx.log(ngx.ERR, "failed to open " .. config_file .. ": ", err_open)
        return false, err_open
    end
    local _, err_write = file:write(jsondata)
    if err_write then
        ngx.log(ngx.ERR, "failed to write " .. config_file .. ": ", err_write)
        return false, err_write
    end
    file:close()
    return true, nil
end

local function safe_set(key, value)
    local ok, err sets:safe_set(key, value)
    if err then
        ngx.log(ngx.ERR, "failed to set key " .. key .. ": ", err)
    end
    return ok, err
end

function _M:get(key)
    return sets:get(key)
end

function _M:get_keys(max_count)
    return sets:get_keys(max_count)
end

function _M:set(key, value)
    local origin_value = sets:get(key)
    local ok, err = safe_set(key, value)
    if err then
        return false, err
    end
    local data = self:dump()
    ok, err = save_config(config_file, data)
    if not ok then
        safe_set(key, origin_value)
    end
    return ok, err
end

function _M:del(key)
    local origin_value = sets:get(key)
    sets:delete(key)
    local data = self:dump()
    local ok, err = save_config(config_file, data)
    if not ok then
        safe_set(key, origin_value)
    end
    return ok, err
end

function _M:setdefault(key, value)
    if not self:get(key) then
        return safe_set(key, value)
    end
end

function _M:load()
    local data, err = load_config(config_file)
    if data then
        sets:flush_all()
        for key, value in pairs(data) do
            safe_set(key, value)
        end
    end
    return save_config(config_file, data)
end

function _M:dump(max_count)
    local data = {}
    for _, key in pairs(self:get_keys(max_count or 1024)) do
        data[key] = self:get(key)
    end
    return data
end

function _M:print(max_count)
    local data = self:dump(max_count or 1024)
    local jsondata, err = prettycjson(data, "\n", "    ") .. "\n"
    if err then
        ngx.log(ngx.ERR, err)
    end
    return jsondata or "{}"
end

function _M:echo(max_count)
    return self:print(max_count or 1024)
end

return _M
