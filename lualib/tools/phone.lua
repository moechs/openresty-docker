local bit32 = require('bit')


local _M = {}



local function byteToUint32(a,b,c,d)
    local _int = 0
    if a then
        _int = _int +  bit32.lshift(a, 24)
    end
    _int = _int + bit32.lshift(b, 16)
    _int = _int + bit32.lshift(c, 8)
    _int = _int + d
    if _int >= 0 then
        return _int
    else
        return _int + math.pow(2, 32)
    end
end


local function getPhoneType(a)
    if a == 1 then
        return "中国移动"
    elseif a == 2 then
        return "中国联通"
    elseif a==3 then
        return "中国电信"
    elseif a==4  then
        return "中国电信虚拟运营商"
    elseif a==5 then
        return "中国联通虚拟运营商"
    elseif a ==6 then
        return "中国移动虚拟运营商"
    elseif a ==7 then
        return "中国广电虚拟运营商"
    else
        return ""
    end
end


function _M.find(phone)
    local file = io.open('/usr/local/data/phone.dat', 'r')
    if not file then return end
    local buf = file:read("*all")
    if buf then file:close() else return end
    local phone = string.sub(phone, 0, 7)
    local int_phone = tonumber(phone)
    local version = string.sub(buf,1,4)
    local firstIndexOffset = byteToUint32(
                string.byte(buf,8),
                string.byte(buf,7),
                string.byte(buf,6),
                string.byte(buf,5)
            )
    local phoneRecordCount = math.floor((string.len(buf) - firstIndexOffset) / 9)
    local left = 0
    local right = phoneRecordCount
    while (left <= right) do
        local middle = math.floor((left + right ) / 2)
        local curOffset = firstIndexOffset + middle * 9
        local indexRecord = string.sub(buf, curOffset+1, curOffset + 9)
        local curPhone = byteToUint32(
                string.byte(indexRecord,4), 
                string.byte(indexRecord,3), 
                string.byte(indexRecord,2), 
                string.byte(indexRecord,1)  
        )
        if curPhone > int_phone then
            right = middle - 1
            
        elseif curPhone < int_phone then
            left = middle + 1
        else 
            local dataOffset = byteToUint32(
                string.byte(indexRecord,8), 
                string.byte(indexRecord,7), 
                string.byte(indexRecord,6), 
                string.byte(indexRecord,5)
            )
            local phone_type = string.byte(indexRecord, 9)
            local endOffset = string.find(buf, '\0', dataOffset + 1)
            local data = string.sub(buf, dataOffset + 1, endOffset - 1)
            if data then
                return string.format("%s%s%s", data, "|" ,getPhoneType(phone_type))
            end
            break
        end
    end
end


return _M
