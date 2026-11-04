local _M = {}

local ipmatcher = require "resty.ipmatcher"
local mlcache   = require "resty.mlcache"
local dns       = require "resty.dns.resolver"
local balancer  = require "ngx.balancer"

local re_find = ngx.re.find

-- ===== 可调配置 =====
local NAMESERVERS   = { "1.1.1.1", "8.8.8.8" }
local ALLOWED_PORTS = { [80]=true, [443]=true, [8080]=true, [8443]=true }  -- 设为 nil 则不限制端口

local BLOCK = assert(ipmatcher.new({
  "0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "127.0.0.0/8",
  "169.254.0.0/16",
  "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16",
  "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24",
  "224.0.0.0/4", "240.0.0.0/4",
  "::1/128", "fc00::/7", "fe80::/10", "::ffff:0:0/96",
}))

local HOST_RE = [[^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$]]
local LOCAL_SUFFIX_RE = [[\.(?:localhost|local|localdomain|internal|lan|intranet|corp|home|arpa)$]]

local cache

function _M.init()
  local c, err = mlcache.new("dns", "dns_cache", {
    lru_size = 2000,
    ttl      = 60,
    neg_ttl  = 10,
    resty_lock_opts = { timeout = 3 },
  })
  if not c then error("mlcache init failed: " .. tostring(err)) end
  cache = c
end

-- ===== 解析并校验目标（access 与 balancer 共用）=====
local function parse_target()
  local host   = ngx.var.myproxy_host
  local port_s = ngx.var.myproxy_port
  local scheme = ngx.var.myproxy_scheme

  if not host or host == "" then return nil, "empty host" end
  host = host:lower()
  if #host > 253 then return nil, "host too long" end
  if scheme ~= "http" and scheme ~= "https" then return nil, "bad scheme" end

  local port = (scheme == "https") and 443 or 80
  if port_s and port_s ~= "" then
    port = tonumber(port_s:sub(2))             -- 去掉前导冒号
    if not port or port < 1 or port > 65535 then return nil, "bad port" end
  end
  if ALLOWED_PORTS and not ALLOWED_PORTS[port] then return nil, "port not allowed" end

  if not re_find(host, HOST_RE, "jo") then return nil, "bad host chars" end
  if not host:find(".", 1, true) then return nil, "single-label host" end
  if re_find(host, LOCAL_SUFFIX_RE, "jo") then return nil, "local suffix" end

  -- 最后一段是纯数字/0x开头，说明是IP写法：只接受标准点分十进制
  local last = host:match("([^.]+)$")
  if re_find(last, [[^(?:\d+|0x[0-9a-f]*)$]], "jo") then
    local a, b, c, d = host:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not a then return nil, "non-standard ip" end
    for _, s in ipairs({ a, b, c, d }) do
      if (#s > 1 and s:sub(1, 1) == "0") or tonumber(s) > 255 then
        return nil, "bad ip octet"
      end
    end
    return { host = host, port = port, scheme = scheme, ips = host }
  end

  return { host = host, port = port, scheme = scheme }
end

-- 任一IP命中黑名单（或无法解析）即视为危险
local function has_blocked(ips_str)
  for ip in ips_str:gmatch("[^,]+") do
    local hit, err = BLOCK:match(ip)
    if hit or err then return true, ip end
  end
  return false
end

-- mlcache 回调：返回逗号拼接的A记录字符串
local function resolve(host)
  local r, err = dns:new{ nameservers = NAMESERVERS, retrans = 2, timeout = 2000 }
  if not r then return nil, "dns init: " .. tostring(err) end

  local answers, qerr = r:query(host, { qtype = r.TYPE_A })
  if not answers then return nil, "dns query: " .. tostring(qerr) end
  if answers.errcode then
    if answers.errcode == 3 then return nil, nil end   -- NXDOMAIN：负缓存
    return nil, "dns errcode " .. answers.errcode      -- 其他错误不缓存
  end

  local ips, ttl = {}, 300
  for _, a in ipairs(answers) do
    if a.type == r.TYPE_A and a.address then
      ips[#ips + 1] = a.address
      if a.ttl and a.ttl < ttl then ttl = a.ttl end
    end
  end
  if #ips == 0 then return nil, nil end

  if ttl < 10 then ttl = 10 end
  return table.concat(ips, ","), nil, ttl
end

local function deny(reason, host)
  ngx.log(ngx.WARN, "SSRF blocked: ", reason, " host=", tostring(host),
          " client=", ngx.var.remote_addr, " uri=", ngx.var.request_uri)
  return ngx.exit(403)
end

-- ===== access 阶段：校验 + 解析 + 预热缓存 =====
function _M.access()
  local t, err = parse_target()
  if not t then return deny(err, ngx.var.myproxy_host) end

  local ips = t.ips
  if not ips then
    local v, gerr = cache:get("dns:" .. t.host, nil, resolve, t.host)
    if gerr then
      ngx.log(ngx.ERR, "dns failed: ", t.host, " ", gerr)
      return ngx.exit(502)
    end
    if not v then return ngx.exit(502) end        -- NXDOMAIN / 无A记录
    ips = v
  end

  local blocked, ip = has_blocked(ips)
  if blocked then return deny("private ip " .. tostring(ip), t.host) end
end

-- ===== balancer 阶段：再次校验并直连IP（不可yield，只读缓存）=====
function _M.balance()
  local t, err = parse_target()
  if not t then
    ngx.log(ngx.ERR, "balancer reject: ", err)
    return ngx.exit(403)
  end

  local ips = t.ips
  if not ips then
    -- stale=true：长下载时后续slice子请求可能晚于TTL，允许使用已校验过的过期值
    local _, _, v = cache:peek("dns:" .. t.host, true)
    if not v then
      ngx.log(ngx.ERR, "balancer: no validated ip for ", t.host)
      return ngx.exit(502)
    end
    ips = v
  end

  local blocked, bip = has_blocked(ips)
  if blocked then
    ngx.log(ngx.ERR, "balancer reject private ip ", tostring(bip), " host=", t.host)
    return ngx.exit(403)
  end

  local list = {}
  for ip in ips:gmatch("[^,]+") do list[#list + 1] = ip end
  local ip = list[math.random(#list)]

  local ok, serr = balancer.set_current_peer(ip, t.port)
  if not ok then
    ngx.log(ngx.ERR, "set_current_peer failed: ", serr)
    return ngx.exit(500)
  end
end

return _M
