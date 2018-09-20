-- utils/parser.lua

local utils = require 'utils.utils'

local Parser = utils.make_class()

function Parser:_init(str, is_file)
  is_file = is_file or false
  self.position = 1
  if is_file then
    local filetext, err = love.filesystem.read(str)
    if filetext then
      self.content = filetext
    else
      error(err)
    end
  else
    self.content = str
  end
  self.finished = false
end

function Parser.fromFile(str)
  return Parser(str, true)
end

function Parser.fromString(str)
  return Parser(str, false)
end

function Parser:get()
  return self.content:at(self.position)
end

function Parser:peek(i)
  return self.content:at(self.position + i)
end

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

function Parser:skip(str)
  while self:is(str) do
    local c = self:next()
    if c == '\\' and not self.finished then
      self:next()
    end
  end
end

return Parser