local common = require 'stats.common'
local stats = ngx.shared.ngx_stats;
local group = ngx.var.stats_group
local req_time = tonumber(ngx.var.request_time) * 1000
local status = tostring(ngx.status)
local cache_status = {"MISS", "BYPASS", "EXPIRED", "STALE", "UPDATING", "REVALIDATED", "HIT"}
local upstream_cache_status = ngx.var.upstream_cache_status

if not group or group == "" then
    group = 'default'
end

common.incr_or_create(stats, common.key({'groups', group, 'requests_total'}), 1)

if req_time >= 0 and req_time < 100 then
    common.incr_or_create(stats, common.key({'groups', group, 'request_times', '0-100'}), 1)
elseif req_time >= 100 and req_time < 500 then
    common.incr_or_create(stats, common.key({'groups', group, 'request_times', '100-500'}), 1)
elseif req_time >= 500 and req_time < 1000 then 
    common.incr_or_create(stats, common.key({'groups', group, 'request_times', '500-1000'}), 1)
elseif req_time >= 1000 and req_time < 5000  then
    common.incr_or_create(stats, common.key({'groups', group, 'request_times', '1000-5000'}), 1)
elseif req_time >= 5000 then
    common.incr_or_create(stats, common.key({'groups', group, 'request_times', '5000+'}), 1)
end

if upstream_cache_status then
    if common.in_table(upstream_cache_status, cache_status) then
        local status = string.lower(upstream_cache_status)
        common.incr_or_create(stats, common.key({'groups', group, 'cache', status}), 1)
    end
end

common.incr_or_create(stats, common.key({'groups', group, 'status', common.get_status_code_class(status)}), 1)

common.incr_or_create(stats, common.key({'groups', group, 'traffic', 'received'}), ngx.var.request_length)
common.incr_or_create(stats, common.key({'groups', group, 'traffic', 'sent'}), ngx.var.bytes_sent)

common.incr_or_create(stats, common.key({'requests', 'total'}), 1) 
