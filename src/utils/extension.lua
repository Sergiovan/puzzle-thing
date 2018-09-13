-- utils/extension.lua

string.at = function(s, i) 
  return s:sub(i, i)
end

string.trim = function(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end