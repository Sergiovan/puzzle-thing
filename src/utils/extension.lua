-- utils/extension.lua

local utf8 = require 'utf8'
local abs = math.abs

--- Gives back character in `s` at position `i`, 
-- or `nil` if `i` is out of bounds
string.at = function(s, i) 
  return abs(i) <= #s and s:sub(i, i) or nil
end

--- Gives back character in utf8 string `s` at position `i`,
-- or `nil` if `i` is out of bounds
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

--- string.sub for utf8 strings
string.utfsub = function(s, f, t)
  return s:sub(utf8.offset(s, f or 1) or 1, t and utf8.offset(s, t + 1) - 1 or -1)
end

--- Removes spaces from the beginning and end of `s`
string.trim = function(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end