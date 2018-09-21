-- utils/extension.lua

local utf8 = require 'utf8'
local abs = math.abs


string.at = function(s, i) 
  return abs(i) <= #s and s:sub(i, i) or nil
end

string.utfat = function(s, i)
  local offset = utf8.offset(s, i)
  if offset == nil then
    return nil
  end
  local textlen = utf8.len(s)
  if i < 0 then
    i = (textlen + 1) + i -- i is negative
  end
  local next_offset = (utf8.offset(s, i + 1) or 0) - 1
  if i <= textlen then 
    return s:sub(offset, next_offset)
  else
    return nil
  end
end

string.utfsub = function(s, f, t)
  return s:sub(utf8.offset(s, f or 1) or 1, t and utf8.offset(s, t + 1) - 1 or -1)
end

string.trim = function(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end