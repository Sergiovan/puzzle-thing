-- utils/parser.lua

local utils = require 'utils.utils'

local Parser = utils.make_class()

--- Initializes parser with a string. 
-- If `is_file` is true, the string is loaded from a file found at `str`
-- else `str` is loaded as-is
function Parser:_init(str, is_file)
  is_file = is_file or false
  self.position = 1 -- Position of the next character to use
  if is_file then
    local filetext, err = love.filesystem.read(str)
    if filetext then
      self.content = filetext -- String to parse
    else
      error(err)
    end
  else
    self.content = str
  end
  self.finished = false -- Wether the parser is done
end

--- Convenience function to make parser from file
function Parser.fromFile(str)
  return Parser(str, true)
end

--- Convenience function to make parser from string
function Parser.fromString(str)
  return Parser(str, false)
end

--- Get the current to-parse character
function Parser:get()
  return self.content:at(self.position)
end

--- Get the character `i` away from the current to-parse character
function Parser:peek(i)
  return self.content:at(self.position + i)
end

--- Checks if the current to-parse character is in `str`
function Parser:is(str)
  local c = self:get()
  if c == nil then
    return false
  end
  if #str == 1 then 
    return c == str
  else
    for v in str:gmatch"." do
      if c == v then
        return true
      end
    end
    return false
  end
end

--- Gets the next character and moves the current 
-- to-parse character up. If the next character is a 
-- space it skips all spaces before giving back `' '`
function Parser:next()
  if self.finished then 
    return nil
  end
  local c = self:get()
  if self:is(' \t\n\r') then 
    while self:is(' \t\n\r') do
      self.position = self.position + 1
    end
    if self:get() == nil then 
      self.finished = true
    end
    return ' '
  end
  self.position = self.position + 1
  if self:get() == nil then 
    self.finished = true
  end
  return c
end

--- Gets characters until one is found that is in `str`
function Parser:til(str)
  local ret = {}
  while not self:is(str) and not self.finished do
    ret[#ret + 1] = self:next()
    if ret[#ret] == '\\' and not self.finished then 
      ret[#ret + 1] = self:next()
    end
  end
  return table.concat(ret, '')
end

--- Skips characters until one is found that is in `str`
function Parser:skip(str)
  while self:is(str) do
    local c = self:next()
    if c == '\\' and not self.finished then
      self:next()
    end
  end
end

return Parser