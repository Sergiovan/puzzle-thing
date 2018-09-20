-- game/board/board.lua

local utils = require 'utils.utils'
local Cells = require 'game.board.cell'
local input = require 'input.input'
local Parser = require 'utils.parser'

local Cell = Cells.Cell
local WallCell = Cells.WallCell

local Board = utils.make_class()

local board_states = {victory = 'victory', defeat = 'defeat', incomplete = 'incomplete'}

Board.board_states = board_states

function Board:_init(x, y, randomize)
  self.x = x
  self.y = y

  self.updated = false

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
          local cellid = level[32 + i + (j-1) * h]
          if type(cellid) == 'number' then 
            self.board[i][j] = Cell.make_cell(cellid)
          else
            self.board[i][j] = Cell.make_cell(cellid.val, unpack(cellid.params))
          end
        end
      end
      self.board[s[1]][s[2]]:enter()
      self.board[s[1]][s[2]]:set_focused(true)
      print(utils.deep_lisp(toks))
    else 
      print(err)
    end
  end
  self.width = self.c * Cell.width
  self.height = self.r * Cell.height
end

function Board:tokenize(input)
  local ret = {}
  local err = {}
  local p = Parser.fromString(input)

  local tuple

  local function str()
    local c = p:next()
    if c ~= '"' then
      err[#err + 1] = 'In string starting at character ' .. (p.position - 1) .. ': String did not start with a quote'
    end
    local ret = p:til('"')
    p:next()
    return ret
  end

  local function value()
    local start = p.position - 1
    if start == 113 then
      local _ = ''
    end
    local val = p:til('",()]')
    local c = p:get()
    
    if c == '"' then
      if val:trim() ~= '' then
        err[#err + 1] = 'In value starting at character ' .. start .. ': String was preceded by data "' .. val .. '"'
      end
      local s = str()
      val = p:til(',)]')
      if val:trim() ~= '' then 
        err[#err + 1] = 'In value starting at character ' .. start .. ': String was succeeded by data "' .. val .. '"'
      end
      if p:get() == nil then
        err[#err + 1] = 'In value starting at character ' .. start .. ': Unexpected EOF'
      end
      return s
    elseif c == '(' then 
      local ret = {}
      if val:trim() ~= '' then
        local num = tonumber(val)
        if num == nil then 
          err[#err + 1] = 'In value starting at character ' .. start .. ': Invalid number'
        end
        ret.val = num
      end
      ret.params = tuple()
      val = p:til(',]')
      if val:trim() ~= '' then 
        err[#err + 1] = 'In value starting at character ' .. start .. ': Parameters were succeeded by data "' .. val .. '"'
      end
      if p:get() == nil then
        err[#err + 1] = 'In value starting at character ' .. start .. ': Unexpected EOF'
      end
      return ret.val and ret or ret.params
    elseif c == ',' or c == ')' or c == ']' then
      local num = tonumber(val)
      if num == nil then 
        err[#err + 1] = 'In value starting at character ' .. start .. ': Invalid number'
      end
      return num    
    elseif c == nil then 
      err[#err + 1] = 'In value starting at character ' .. start .. ': Unexpected EOF'
      return tonumber(val)
    end
  end

  function tuple()
    local start = p.position
    local ret = ''
    local tupl = {}
    
    local c = p:next()
    if c ~= '(' then
      err[#err + 1] = 'In tuple starting at character ' .. start .. ': Tuple did not start with a paren'
    end
    
    while c do
      tupl[#tupl + 1] = value()
      c = p:next()
      if c == ')' then
        break
      elseif c == nil then
        break
      elseif c ~= ',' then
        err[#err + 1] = 'In tuple starting at character ' .. start .. ': Invalid separator "' .. c .. '"'
      end
    end
    
    if c == nil then 
      err[#err + 1] = 'In tuple starting at character ' .. start .. ': Unexpected EOF'
    end
    return tupl
  end

  local function level()
    local start = p.position
    local ret = ''
    local level = {}
    
    local c = p:next()
    if c ~= '[' then
      err[#err + 1] = 'In level starting at character ' .. start .. ': level did not start with a bracket'
    end
    
    while c do
      level[#level + 1] = value()
      c = p:next()
      if c == ']' then
        break
      elseif c == nil then
        break
      elseif c ~= ',' then
        err[#err + 1] = 'In level starting at character ' .. start .. ': Invalid separator "' .. c .. '"'
      end
    end
    
    if c == nil then 
      err[#err + 1] = 'In level starting at character ' .. start .. ': Unexpected EOF'
    end
    return level
  end
  
  p:til('[')
  while not p.finished do 
    ret[#ret + 1] = level()
    p:til('[')
  end
  
  if #err then 
    for k, v in ipairs(err) do
      print(v)
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
  self.updated = false
  local mx, my = input:get_mouse_position()

  local cx, cy = self:board_coords(mx, my)
  if not cx then
    return
  end

  -- TODO handle collisions
  local check_victory = false


  local fx, fy = unpack(self.focused)
  if math.abs(cx - fx) + math.abs(cy - fy) == 1 then
    local cell = self.board[cx][cy]
    if cell and cell:can_enter() then
      self.board[fx][fy]:set_focused(false)
      cell:enter()
      cell:set_focused(true)
      self.focused = {cx, cy}
      self.updated = true
    end
  end
end

function Board:getBoardState()
  local total = 0
  for i=1, self.c do
    for j=1, self.r do
      total = total + self.board[i][j].value
    end
  end
  if total == 0 then
    return board_states.victory
  else
    local n, e, s, w = self:getDirections()
    if n or e or s or w then 
      return board_states.incomplete
    else
      return board_states.defeat
    end
  end
end

function Board:getDirections()
  local n, e, s, w = false, false, false, false
  local fx, fy = unpack(self.focused)
  local nc = self:at(fx, fy - 1)
  local ec = self:at(fx + 1, fy)
  local sc = self:at(fx, fy + 1)
  local wc = self:at(fx - 1, fy)
  n = nc and nc:can_enter()
  e = ec and ec:can_enter()
  s = sc and sc:can_enter()
  w = wc and wc:can_enter()
  return n, e, s, w
end

return Board