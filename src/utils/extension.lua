-- utils/extension.lua

string.at = function(s, i) 
  return i <= #s and s:sub(i, i) or nil
end

string.trim = function(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end