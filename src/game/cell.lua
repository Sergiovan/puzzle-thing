-- game/cell.lua
local utils = require 'utils.utils'
local module

Cell = utils.make_class()

Cell.width = 50
Cell.height = 50

function Cell:_init(x, y)
  self.x = x
  self.y = y
end

function Cell:draw()
  love.graphics.rectangle('fill', self.x, self.y, Cell.width, Cell.height)
end

module.Cell = Cell

return module
