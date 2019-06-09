-- game/cell.lua
local utils = require 'utils.utils'
local module = {}

local Cell = utils.make_class()

Cell.width = 50
Cell.height = 50

Cell.color = {{248/255, 40/255, 89/255}, {62/255, 193/255, 247/255}}
Cell.border_color = {{198/255, 0, 39/255}, {12/255, 143/255, 197/255}}
Cell.focused_color = {250/255, 231/255, 96/255}
Cell.focused_border_color = {200/255, 181/255, 46/255}

function Cell:_init()
  self.value = 1 -- Value of the cell
  self.solid = false -- If this cell is impassable
  self.focused = false -- If this cell is currently focused
end

--- Draws the cell at (`x`, `y`)
function Cell:draw(x, y)
  local c = {love.graphics.getColor()}
  love.graphics.setColor(self.focused and self.focused_border_color or self.border_color[self.value + 1])
  love.graphics.rectangle('fill', x, y, self.width, self.height)
  love.graphics.setColor(self.focused and self.focused_color or self.color[self.value + 1])
  love.graphics.rectangle('fill', 1+x, 1+y, self.width-2, self.height-2)
  love.graphics.setColor(c)
end

--- If this cell is impassable
function Cell:solid()
  return self.solid
end

--- If this cell can be entered
function Cell:can_enter()
  return not self.solid and self.value > 0
end

--- Enter the cell
function Cell:enter()
  self.value = self.value - 1
end

--- Sets the cell as focused
function Cell:set_focused(focused)
  self.focused = focused
end

local WallCell = utils.make_class(Cell)
WallCell.color = {0, 0, 0}
WallCell.border_color = {25, 25, 25 }

function WallCell:_init()
  Cell._init(self) -- I am a genius
  self.value = 0
  self.solid = true
end

function WallCell:draw(x, y)
  local c = {love.graphics.getColor()}
  love.graphics.setColor(self.border_color)
  love.graphics.rectangle('fill', x, y, self.width, self.height)
  love.graphics.setColor(self.color)
  love.graphics.rectangle('fill', 1+x, 1+y, self.width-2, self.height-2)
  love.graphics.setColor(c)
end

Cell.id_to_cell = {
  [0] = WallCell,
  [1] = Cell
}

function Cell.make_cell(id, ...)
  local class = Cell.id_to_cell[id]
  if class then 
    return class(...)
  end
  return nil
end

module.Cell = Cell
module.WallCell = WallCell

return module
