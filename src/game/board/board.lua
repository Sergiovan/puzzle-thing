-- game/board/board.lua

local utils = require 'utils.utils'
local Cells = require 'game.board.cell'
local input = require 'input.input'

local Cell = Cells.Cell
local WallCell = Cells.WallCell

local Board = utils.make_class()

function Board:_init(x, y, r, c)
  self.x = x
  self.y = y
  self.c = c
  self.r = r
  self.width = self.c * Cell.width
  self.height = self.r * Cell.height
  self.focused = {1,1}
  self.board = {}
  for i=1, r do
    self.board[i] = {}
    for j=1, c do
      local cell = love.math.random(1,10) == 1 and WallCell or Cell
      self.board[i][j] = cell(x + (i-1) * cell.width, y + (j-1) * cell.height)
    end
  end
  self.board[1][1]:enter()
  self.board[1][1]:set_focused(true)
end

-- TODO
function Board:load()

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
      self.board[i][j]:draw(x, y)
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
