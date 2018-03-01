-- game/cell.lua
local utils = require 'utils.utils'
local module = {}

Cell = utils.make_class()

Cell.width = 50
Cell.height = 50

Cell.color = {{248, 40, 89}, {62, 193, 247}}
Cell.border_color = {{198, 0, 39}, {12, 143, 197}}
Cell.focused_color = {250, 231, 96}
Cell.focused_border_color = {200, 181, 46}

function Cell:_init(x, y)
  self.x = x
  self.y = y
  self.value = 1
  self.solid = false
end

function Cell:draw(focused)
  love.graphics.setColor(focused and self.focused_border_color or self.border_color[self.value + 1])
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
  love.graphics.setColor(focused and self.focused_color or self.color[self.value + 1])
  love.graphics.rectangle('fill', self.x+1, self.y+1, self.width-2, self.height-2)
end

function Cell:solid()
  return self.solid
end

function Cell:can_enter()
  return not self.solid and self.value > 0
end

function Cell:enter()
  self.value = self.value - 1
end

WallCell = utils.make_class(Cell)
WallCell.color = {0, 0, 0}
WallCell.border_color = {25, 25, 25 }

function WallCell:_init(x, y)
  Cell._init(self, x, y) -- I am a genius
  self.value = 0
  self.solid = true
end

function WallCell:draw(_)
  love.graphics.setColor(self.border_color)
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
  love.graphics.setColor(self.color)
  love.graphics.rectangle('fill', self.x+1, self.y+1, self.width-2, self.height-2)
end

module.Cell = Cell
module.WallCell = WallCell

return module
