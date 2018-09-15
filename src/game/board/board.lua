-- game/board/board.lua

local utils = require 'utils.utils'
local Cells = require 'game.board.cell'
local input = require 'input.input'

local Cell = Cells.Cell
local WallCell = Cells.WallCell

local Board = utils.make_class()

function Board:_init(x, y, randomize)
  self.x = x
  self.y = y

  local err, mess = self:load(randomize and 'random' or '')
  if err then 
    print(mess)
  end

end

-- TODO
function Board:load(file, num)
  num = num or 1
  if file == 'randomize' then 
    self.c = 10
    self.r = 10
    self.focused = {1,1}
    self.board = {}
    for i=1, r do
      self.board[i] = {}
      for j=1, c do
        local cell = love.math.random(1,10) == 1 and WallCell or Cell
        self.board[i][j] = cell()
      end
    end
    self.board[1][1]:enter()
    self.board[1][1]:set_focused(true)
  elseif not file or #file == 0 then 
    self.c = 10
    self.r = 10
    self.focused = {1,1}
    self.board = {}
    for i=1, self.r do
      self.board[i] = {}
      for j=1, self.c do
        self.board[i][j] = Cell()
      end
    end
    self.board[1][1]:enter()
    self.board[1][1]:set_focused(true)
  else
    local filetext, err = love.filesystem.read(file)
    if filetext then 
      local toks = self:tokenize(filetext) -- TODO Level handler or something
      local level = toks[num]
      local version = level[1]
      -- Ignore version for now
      local w, h, s, n, d = unpack(level, 2, 32)
      self.c = w
      self.r = h
      local total = w * h
      if #level < total + 32 then 
        return false, "Level " .. num .. " only has " .. #level .. " fields when " .. (total + 32) .. " were expected"
      end
      self.focused = s
      self.board = {}
      for i=1, h do
        self.board[i] = {}
        for j=1, w do 
          self.board[i][j] = Cell.make_cell(level[32 + i + (j-1) * h])
        end
      end
      self.board[s[1]][s[2]]:enter()
      self.board[s[1]][s[2]]:set_focused(true)
      print(utils.deep_lisp(self.board))
    else 
      print(err)
    end
  end
  self.width = self.c * Cell.width
  self.height = self.r * Cell.height
end

function Board:tokenize(string)
  local ret = {}

  local function str(i)
    i = i + 1
    local str = ''
    local char = string:at(i)

    while char and char ~= '"' do 
      if char == '\\' then 
        i = i + 1
        char = string:at(i)
      end
      str = str .. char
      i = i + 1
      char = string:at(i)
    end
    i = i + 1
    return i, str
  end

  local function tuple(i)
    i = i + 1
    local tuple = {}
    local cur = ''
    local char = string:at(i)
    local special = false

    while char and char ~= ')' do 
      if char == '\\' then
        i = i + 1
        char = string:at(i)
        cur = cur .. char
        i = i + 1
      elseif char == '"' then 
        local s
        i, s = str(i)
        level[#level + 1] = s
        special = true
      elseif char == ',' then
        if special then 
          special = false
        else
          tuple[#tuple + 1] = tonumber(cur) or 0
        end
        cur = ''
        i = i + 1
      elseif char == ' ' or char == '\t' or char == '\n' or char == '\r' then 
        i = i + 1 
      else 
        cur = cur .. char
        i = i + 1
      end
      char = string:at(i)
    end
    if special then 
      special = false
    else
      tuple[#tuple + 1] = tonumber(cur) or 0
    end
    cur = ''
    i = i + 1
    return i, tuple
  end

  local function level(i)
    i = i + 1
    local level = {}
    local cur = ''
    local char = string:at(i)
    local special = false

    while char and char ~= ']' do
      if char == '\\' then 
        i = i + 1
        char = string:at(i)
        cur = cur .. char
        i = i + 1
      elseif char == '(' then 
        local t
        i, t = tuple(i)
        level[#level + 1] = t
        special = true
      elseif char == '"' then
        local s
        i, s = str(i)
        level[#level + 1] = s
        special = true
      elseif char == ' ' or char == '\t' or char == '\n' or char == '\r' then 
        i = i + 1 
      elseif char == ',' then
        if special then 
          special = false
        else
          level[#level + 1] = tonumber(cur) or 0
        end
        cur = ''
        i = i + 1
      else
        cur = cur .. char
        i = i + 1
      end
      char = string:at(i)
    end
    if special then 
      special = false
    else
      level[#level + 1] = tonumber(cur) or 0
    end
    cur = ''
    i = i + 1
    return i, level
  end
  
  local i = 1
  local char = string:at(i)
  while char do
    if char == '\\' then 
      i = i + 1
      char = string:at(i)
    elseif char == '[' then
      local l
      i, l = level(i)
      ret[#ret + 1] = l
      char = string:at(i)
    else
      i = i + 1
      char = string:at(i)
    end
  end

  return ret
end

function Board:board_coords(x, y)
  if x < self.x or x >= self.x + self.width or y < self.y or y >= self.y + self.height then
    return nil, nil
  end
  return math.floor((x - self.x)/50) + 1, math.floor((y - self.y)/50) + 1
end

function Board:at(x, y)
  return self.board[x] and self.board[x][y] or nil
end

function Board:draw(x, y)
  x = x or 0
  y = y or 0
  for i=1, self.c do
    for j=1, self.r do
      self.board[i][j]:draw(x + self.x + (i-1) * Cell.width, y + self.y + (j-1) * Cell.height)
    end
  end
end

function Board:update(dt)
  local mx, my = input:get_mouse_position()

  local cx, cy = self:board_coords(mx, my)
  if not cx then
    return
  end

  -- TODO handle collisions

  local fx, fy = unpack(self.focused)
  if math.abs(cx - fx) + math.abs(cy - fy) == 1 then
    local cell = self.board[cx][cy]
    if cell and cell:can_enter() then
      self.board[fx][fy]:set_focused(false)
      cell:enter()
      cell:set_focused(true)
      self.focused = {cx, cy}
    end
  end
end

return Board