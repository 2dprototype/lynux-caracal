-- lib/base64.lua
local base64 = {}

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function base64.encode(data)
    local bytes = {}
    for i = 1, #data do
        bytes[i] = string.byte(data, i)
    end
    
    local result = {}
    for i = 1, #bytes, 3 do
        local a, b1, c = bytes[i], bytes[i+1], bytes[i+2]
        local n = (a or 0) * 0x10000 + (b1 or 0) * 0x100 + (c or 0)
        
        local chars = {
            b:sub(math.floor(n / 0x40000) + 1, math.floor(n / 0x40000) + 1),
            b:sub(math.floor(n / 0x1000) % 0x40 + 1, math.floor(n / 0x1000) % 0x40 + 1),
            b:sub(math.floor(n / 0x40) % 0x40 + 1, math.floor(n / 0x40) % 0x40 + 1),
            b:sub(n % 0x40 + 1, n % 0x40 + 1)
        }
        
        if not b1 then chars[3] = '=' end
        if not c then chars[4] = '=' end
        
        result[#result + 1] = table.concat(chars)
    end
    
    return table.concat(result)
end

function base64.decode(data)
    local bytes = {}
    for i = 1, #data do
        bytes[i] = string.byte(data, i)
    end
    
    local result = {}
    local pos = 1
    while pos <= #bytes do
        local chars = {}
        for i = 1, 4 do
            local c = bytes[pos + i - 1]
            if c == 61 then -- '='
                chars[i] = 0
            else
                local idx = b:find(string.char(c), 1, true)
                chars[i] = idx and idx - 1 or 0
            end
        end
        pos = pos + 4
        
        local n = chars[1] * 0x40000 + chars[2] * 0x1000 + chars[3] * 0x40 + chars[4]
        
        local c1 = math.floor(n / 0x10000) % 0x100
        local c2 = math.floor(n / 0x100) % 0x100
        local c3 = n % 0x100
        
        result[#result + 1] = string.char(c1)
        if chars[3] ~= 0 then result[#result + 1] = string.char(c2) end
        if chars[4] ~= 0 then result[#result + 1] = string.char(c3) end
    end
    
    return table.concat(result)
end

return base64